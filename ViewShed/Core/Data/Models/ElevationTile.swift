import Foundation
import SwiftData

/// SwiftData model for caching elevation data tiles
@Model
final class ElevationTile {
    @Attribute(.unique) var tileKey: String // "z_x_y" format
    var zoom: Int
    var tileX: Int
    var tileY: Int
    var data: Data // Terrain-RGB tile data
    var cachedAt: Date
    var lastAccessedAt: Date
    var accessCount: Int

    init(
        zoom: Int,
        tileX: Int,
        tileY: Int,
        data: Data,
        cachedAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        accessCount: Int = 1
    ) {
        self.tileKey = "\(zoom)_\(tileX)_\(tileY)"
        self.zoom = zoom
        self.tileX = tileX
        self.tileY = tileY
        self.data = data
        self.cachedAt = cachedAt
        self.lastAccessedAt = lastAccessedAt
        self.accessCount = accessCount
    }

    /// Update access tracking
    func markAccessed() {
        lastAccessedAt = Date()
        accessCount += 1
    }

    /// Check if tile is stale (older than 30 days)
    var isStale: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return cachedAt < thirtyDaysAgo
    }
}
