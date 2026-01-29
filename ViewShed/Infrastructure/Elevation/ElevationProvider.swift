import Foundation
import CoreLocation

/// Provides elevation data for coordinates using MapBox Terrain-RGB tiles
final class ElevationProvider {
    static let shared = ElevationProvider()

    private let cache = TerrainTileCache.shared
    private let session: URLSession
    private let zoom = AppConstants.Elevation.tileZoomLevel // 14 gives ~10m resolution
    private let downloadQueue = DispatchQueue(label: "com.viewshed.elevation.download", attributes: .concurrent)
    private var pendingDownloads: [String: [(Result<[[Float]], Error>) -> Void]] = [:]
    private let pendingLock = NSLock()

    /// MapBox access token from Info.plist
    private var accessToken: String {
        Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ?? ""
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.requestTimeout
        config.urlCache = nil // We manage our own cache
        session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Get elevation at a specific coordinate
    /// Returns elevation in meters, or nil if not available
    func elevation(at coordinate: Coordinate) async -> Float? {
        let (tileX, tileY, pixelX, pixelY) = TileUtilities.pixelXY(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: zoom
        )

        guard let grid = await getElevationGrid(x: tileX, y: tileY) else {
            return nil
        }

        return TerrainRGBDecoder.interpolatedElevation(from: grid, x: pixelX, y: pixelY)
    }

    /// Get elevation at a CLLocationCoordinate2D
    func elevation(at coordinate: CLLocationCoordinate2D) async -> Float? {
        await elevation(at: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    /// Get elevations for multiple coordinates efficiently (batched tile fetching)
    func elevations(at coordinates: [Coordinate]) async -> [Float?] {
        // Group coordinates by tile
        var tileGroups: [String: [(index: Int, pixelX: Double, pixelY: Double)]] = [:]

        for (index, coord) in coordinates.enumerated() {
            let (tileX, tileY, pixelX, pixelY) = TileUtilities.pixelXY(
                latitude: coord.latitude,
                longitude: coord.longitude,
                zoom: zoom
            )
            let key = "\(tileX)_\(tileY)"
            if tileGroups[key] == nil {
                tileGroups[key] = []
            }
            tileGroups[key]!.append((index: index, pixelX: pixelX, pixelY: pixelY))
        }

        // Fetch all needed tiles concurrently
        var results = [Float?](repeating: nil, count: coordinates.count)

        await withTaskGroup(of: (String, [[Float]]?).self) { group in
            for (key, _) in tileGroups {
                let parts = key.split(separator: "_")
                let tileX = Int(parts[0])!
                let tileY = Int(parts[1])!

                group.addTask {
                    let grid = await self.getElevationGrid(x: tileX, y: tileY)
                    return (key, grid)
                }
            }

            for await (key, grid) in group {
                guard let grid = grid, let coords = tileGroups[key] else { continue }
                for (index, pixelX, pixelY) in coords {
                    results[index] = TerrainRGBDecoder.interpolatedElevation(from: grid, x: pixelX, y: pixelY)
                }
            }
        }

        return results
    }

    // MARK: - Tile Management

    /// Get elevation grid for a tile (from cache or download)
    private func getElevationGrid(x: Int, y: Int) async -> [[Float]]? {
        // Check cache first
        if let cached = cache.getElevationGrid(x: x, y: y, zoom: zoom) {
            return cached
        }

        // Download tile
        return await downloadTile(x: x, y: y)
    }

    /// Download a terrain tile from MapBox
    private func downloadTile(x: Int, y: Int) async -> [[Float]]? {
        let urlString = "https://api.mapbox.com/v4/mapbox.terrain-rgb/\(zoom)/\(x)/\(y)@2x.pngraw?access_token=\(accessToken)"

        guard let url = URL(string: urlString) else {
            print("Invalid tile URL")
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Tile download failed: \(x), \(y)")
                return nil
            }

            // Decode and cache
            return cache.storeRawTile(data, x: x, y: y, zoom: zoom)
        } catch {
            print("Tile download error: \(error)")
            return nil
        }
    }

    // MARK: - Pre-download Region

    /// Pre-download tiles for a region (for offline use)
    func downloadRegion(
        center: Coordinate,
        radiusMeters: Double,
        progress: @escaping (Int, Int) -> Void
    ) async -> Bool {
        print("🌍 Calculating tiles for region: \(center.latitude), \(center.longitude) radius: \(radiusMeters)m")
        let tiles = tilesForRegion(center: center, radiusMeters: radiusMeters)
        let total = tiles.count
        print("📦 Total tiles to download: \(total)")
        
        guard total > 0 else { return true }
        
        var completed = 0
        // Report 0%
        progress(0, total)

        await withTaskGroup(of: Bool.self) { group in
            // Limit concurrent downloads
            let semaphore = AsyncSemaphore(limit: 4)

            for (x, y) in tiles {
                group.addTask {
                    await semaphore.wait()
                    // Use a do-block to ensure signal is called
                    let result: Bool = await {
                        if self.cache.hasTile(x: x, y: y, zoom: self.zoom) {
                            return true
                        }
                        let res = await self.downloadTile(x: x, y: y)
                        return res != nil
                    }()
                    await semaphore.signal()
                    return result
                }
            }

            for await _ in group {
                completed += 1
                progress(completed, total)
                if completed % 10 == 0 {
                    print("⬇️ Download progress: \(completed)/\(total)")
                }
            }
        }
        
        print("✅ Download region complete")
        return true
    }

    /// Calculate which tiles are needed to cover a circular region
    func tilesForRegion(center: Coordinate, radiusMeters: Double) -> [(x: Int, y: Int)] {
        var tiles: Set<String> = []

        // Sample points around the circle to find all tiles
        let steps = 36 // Check every 10 degrees
        for i in 0...steps {
            let angle = Double(i) * 360.0 / Double(steps)
            let edgePoint = center.destination(distance: radiusMeters, bearing: angle)

            let (x, y) = TileUtilities.tileXY(latitude: edgePoint.latitude, longitude: edgePoint.longitude, zoom: zoom)
            tiles.insert("\(x)_\(y)")
        }

        // Add center tile
        let (cx, cy) = TileUtilities.tileXY(latitude: center.latitude, longitude: center.longitude, zoom: zoom)
        tiles.insert("\(cx)_\(cy)")

        // Fill in the rectangle of tiles
        var result: [(x: Int, y: Int)] = []
        var minX = Int.max, maxX = Int.min, minY = Int.max, maxY = Int.min

        for tile in tiles {
            let parts = tile.split(separator: "_")
            let x = Int(parts[0])!
            let y = Int(parts[1])!
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }

        for x in minX...maxX {
            for y in minY...maxY {
                result.append((x: x, y: y))
            }
        }

        return result
    }

    /// Check how many tiles are cached for a region
    func cachedTileCount(center: Coordinate, radiusMeters: Double) -> (cached: Int, total: Int) {
        let tiles = tilesForRegion(center: center, radiusMeters: radiusMeters)
        var cached = 0

        for (x, y) in tiles {
            if cache.hasTile(x: x, y: y, zoom: zoom) {
                cached += 1
            }
        }

        return (cached: cached, total: tiles.count)
    }
}

// MARK: - Async Semaphore for concurrency limiting

actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.count = limit
    }

    func wait() async {
        if count > 0 {
            count -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }

    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            count += 1
        }
    }
}
