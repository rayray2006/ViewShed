import Foundation
import SwiftData

/// SwiftData model for persisting viewed area grid cells
@Model
final class ViewedAreaEntity {
    @Attribute(.unique) var cellKey: String // "x_y" format for uniqueness
    var gridX: Int
    var gridY: Int
    var firstSeenAt: Date
    var lastSeenAt: Date
    var viewCount: Int

    init(gridX: Int, gridY: Int, firstSeenAt: Date, lastSeenAt: Date, viewCount: Int) {
        self.cellKey = "\(gridX)_\(gridY)"
        self.gridX = gridX
        self.gridY = gridY
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.viewCount = viewCount
    }

    /// Convert to domain GridCell model
    func toGridCell() -> GridCell {
        GridCell(gridX: gridX, gridY: gridY)
    }

    /// Create from domain GridCell model
    static func from(gridCell: GridCell, firstSeenAt: Date = Date(), viewCount: Int = 1) -> ViewedAreaEntity {
        ViewedAreaEntity(
            gridX: gridCell.gridX,
            gridY: gridCell.gridY,
            firstSeenAt: firstSeenAt,
            lastSeenAt: Date(),
            viewCount: viewCount
        )
    }

    /// Update when viewed again
    func markViewed() {
        lastSeenAt = Date()
        viewCount += 1
    }
}
