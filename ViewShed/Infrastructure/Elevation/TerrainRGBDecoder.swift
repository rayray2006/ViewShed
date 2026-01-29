import Foundation
import UIKit
import CoreGraphics

/// Decodes MapBox Terrain-RGB tiles to elevation data
final class TerrainRGBDecoder {

    /// Tile size in pixels (MapBox uses 512x512 for terrain)
    static let tileSize = 512

    /// Decode a Terrain-RGB PNG image to elevation grid
    /// Returns a 512x512 array of elevations in meters
    static func decode(imageData: Data) -> [[Float]]? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        // Create a context to read pixel data
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            return nil
        }

        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // Decode each pixel to elevation
        var elevations = [[Float]](repeating: [Float](repeating: 0, count: width), count: height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Float(data[offset])
                let g = Float(data[offset + 1])
                let b = Float(data[offset + 2])

                // MapBox Terrain-RGB formula:
                // elevation = -10000 + ((R * 256 * 256 + G * 256 + B) * 0.1)
                let elevation = -10000.0 + ((r * 256.0 * 256.0 + g * 256.0 + b) * 0.1)
                elevations[y][x] = elevation
            }
        }

        return elevations
    }

    /// Get elevation at a specific pixel within a tile
    static func elevation(from grid: [[Float]], x: Int, y: Int) -> Float {
        guard y >= 0 && y < grid.count && x >= 0 && x < grid[0].count else {
            return 0
        }
        return grid[y][x]
    }

    /// Bilinear interpolation for sub-pixel accuracy
    static func interpolatedElevation(from grid: [[Float]], x: Double, y: Double) -> Float {
        let x0 = Int(x)
        let y0 = Int(y)
        let x1 = min(x0 + 1, grid[0].count - 1)
        let y1 = min(y0 + 1, grid.count - 1)

        let xFrac = Float(x - Double(x0))
        let yFrac = Float(y - Double(y0))

        let e00 = elevation(from: grid, x: x0, y: y0)
        let e10 = elevation(from: grid, x: x1, y: y0)
        let e01 = elevation(from: grid, x: x0, y: y1)
        let e11 = elevation(from: grid, x: x1, y: y1)

        // Bilinear interpolation
        let e0 = e00 * (1 - xFrac) + e10 * xFrac
        let e1 = e01 * (1 - xFrac) + e11 * xFrac
        return e0 * (1 - yFrac) + e1 * yFrac
    }
}

/// Utilities for converting between coordinates and tile indices
enum TileUtilities {
    /// Convert latitude/longitude to tile coordinates at a given zoom level
    static func tileXY(latitude: Double, longitude: Double, zoom: Int) -> (x: Int, y: Int) {
        let n = pow(2.0, Double(zoom))
        let x = Int((longitude + 180.0) / 360.0 * n)

        let latRad = latitude * .pi / 180.0
        let y = Int((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n)

        return (x: x, y: y)
    }

    /// Convert latitude/longitude to pixel position within a tile
    static func pixelXY(latitude: Double, longitude: Double, zoom: Int, tileSize: Int = 512) -> (tileX: Int, tileY: Int, pixelX: Double, pixelY: Double) {
        let n = pow(2.0, Double(zoom))

        let xTile = (longitude + 180.0) / 360.0 * n
        let tileX = Int(xTile)
        let pixelX = (xTile - Double(tileX)) * Double(tileSize)

        let latRad = latitude * .pi / 180.0
        let yTile = (1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n
        let tileY = Int(yTile)
        let pixelY = (yTile - Double(tileY)) * Double(tileSize)

        return (tileX: tileX, tileY: tileY, pixelX: pixelX, pixelY: pixelY)
    }

    /// Convert tile coordinates back to latitude/longitude (top-left corner of tile)
    static func tileToLatLon(x: Int, y: Int, zoom: Int) -> (latitude: Double, longitude: Double) {
        let n = pow(2.0, Double(zoom))
        let longitude = Double(x) / n * 360.0 - 180.0
        let latRad = atan(sinh(.pi * (1 - 2 * Double(y) / n)))
        let latitude = latRad * 180.0 / .pi
        return (latitude: latitude, longitude: longitude)
    }

    /// Get tile bounds (for a given tile x, y, zoom)
    static func tileBounds(x: Int, y: Int, zoom: Int) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let topLeft = tileToLatLon(x: x, y: y, zoom: zoom)
        let bottomRight = tileToLatLon(x: x + 1, y: y + 1, zoom: zoom)
        return (minLat: bottomRight.latitude, maxLat: topLeft.latitude,
                minLon: topLeft.longitude, maxLon: bottomRight.longitude)
    }

    /// Calculate meters per pixel at a given latitude and zoom
    static func metersPerPixel(latitude: Double, zoom: Int, tileSize: Int = 512) -> Double {
        let earthCircumference = 40075016.686 // meters at equator
        let latRad = latitude * .pi / 180.0
        return earthCircumference * cos(latRad) / (pow(2.0, Double(zoom)) * Double(tileSize))
    }
}
