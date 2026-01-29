import Foundation

/// Manages offline storage and caching of terrain tiles
final class TerrainTileCache {
    static let shared = TerrainTileCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let memoryCache = NSCache<NSString, ElevationGrid>()
    private let queue = DispatchQueue(label: "com.viewshed.tilecache", attributes: .concurrent)

    /// Wrapper class for elevation grid (NSCache requires class type)
    final class ElevationGrid {
        let grid: [[Float]]
        init(grid: [[Float]]) {
            self.grid = grid
        }
    }

    private init() {
        // Create cache directory
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("TerrainTiles", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        memoryCache.countLimit = 100 // Keep up to 100 tiles in memory
        memoryCache.totalCostLimit = 100 * 512 * 512 * 4 // ~100MB
    }

    // MARK: - Cache Key

    private func cacheKey(x: Int, y: Int, zoom: Int) -> String {
        return "\(zoom)_\(x)_\(y)"
    }

    private func filePath(x: Int, y: Int, zoom: Int) -> URL {
        let key = cacheKey(x: x, y: y, zoom: zoom)
        return cacheDirectory.appendingPathComponent("\(key).terrain")
    }

    // MARK: - Read/Write

    /// Get elevation grid from cache (memory first, then disk)
    func getElevationGrid(x: Int, y: Int, zoom: Int) -> [[Float]]? {
        let key = cacheKey(x: x, y: y, zoom: zoom) as NSString

        // Check memory cache first
        if let cached = memoryCache.object(forKey: key) {
            return cached.grid
        }

        // Check disk cache
        let path = filePath(x: x, y: y, zoom: zoom)
        guard fileManager.fileExists(atPath: path.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: path)
            if let grid = deserializeGrid(data) {
                // Store in memory cache
                memoryCache.setObject(ElevationGrid(grid: grid), forKey: key)
                return grid
            }
        } catch {
            print("Error reading tile from disk: \(error)")
        }

        return nil
    }

    /// Store elevation grid to cache
    func storeElevationGrid(_ grid: [[Float]], x: Int, y: Int, zoom: Int) {
        let key = cacheKey(x: x, y: y, zoom: zoom) as NSString

        // Store in memory cache
        memoryCache.setObject(ElevationGrid(grid: grid), forKey: key)

        // Store to disk asynchronously
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let path = self.filePath(x: x, y: y, zoom: zoom)
            if let data = self.serializeGrid(grid) {
                try? data.write(to: path)
            }
        }
    }

    /// Store raw PNG data and decode it
    func storeRawTile(_ imageData: Data, x: Int, y: Int, zoom: Int) -> [[Float]]? {
        guard let grid = TerrainRGBDecoder.decode(imageData: imageData) else {
            return nil
        }
        storeElevationGrid(grid, x: x, y: y, zoom: zoom)
        return grid
    }

    // MARK: - Serialization

    private func serializeGrid(_ grid: [[Float]]) -> Data? {
        let height = grid.count
        let width = grid.isEmpty ? 0 : grid[0].count

        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: Int32(width)) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: Int32(height)) { Array($0) })

        for row in grid {
            for value in row {
                data.append(contentsOf: withUnsafeBytes(of: value) { Array($0) })
            }
        }

        return data
    }

    private func deserializeGrid(_ data: Data) -> [[Float]]? {
        guard data.count >= 8 else { return nil }

        var offset = 0

        let width = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4
        let height = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
        offset += 4

        let expectedSize = 8 + Int(width) * Int(height) * 4
        guard data.count >= expectedSize else { return nil }

        var grid = [[Float]]()
        grid.reserveCapacity(Int(height))

        for _ in 0..<height {
            var row = [Float]()
            row.reserveCapacity(Int(width))
            for _ in 0..<width {
                let value = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self) }
                row.append(value)
                offset += 4
            }
            grid.append(row)
        }

        return grid
    }

    // MARK: - Cache Management

    /// Check if a tile is cached
    func hasTile(x: Int, y: Int, zoom: Int) -> Bool {
        let key = cacheKey(x: x, y: y, zoom: zoom) as NSString
        if memoryCache.object(forKey: key) != nil {
            return true
        }
        let path = filePath(x: x, y: y, zoom: zoom)
        return fileManager.fileExists(atPath: path.path)
    }

    /// Get list of all cached tiles
    func cachedTiles() -> [(x: Int, y: Int, zoom: Int)] {
        var tiles: [(x: Int, y: Int, zoom: Int)] = []

        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return tiles
        }

        for file in files {
            let name = file.deletingPathExtension().lastPathComponent
            let parts = name.split(separator: "_")
            if parts.count == 3,
               let zoom = Int(parts[0]),
               let x = Int(parts[1]),
               let y = Int(parts[2]) {
                tiles.append((x: x, y: y, zoom: zoom))
            }
        }

        return tiles
    }

    /// Clear all cached tiles
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get cache size in bytes
    func cacheSize() -> Int64 {
        var size: Int64 = 0
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for file in files {
            if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
               let fileSize = attrs[.size] as? Int64 {
                size += fileSize
            }
        }

        return size
    }
}
