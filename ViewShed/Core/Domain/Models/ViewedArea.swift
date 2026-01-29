import Foundation

/// Represents the cumulative viewed area across all viewshed calculations
struct ViewedArea: Codable, Sendable {
    let cells: Set<GridCell>
    let totalAreaKm2: Double
    let lastUpdated: Date

    init(cells: Set<GridCell>, lastUpdated: Date = Date()) {
        self.cells = cells
        self.totalAreaKm2 = Double(cells.count) * GridCell.cellAreaKm2
        self.lastUpdated = lastUpdated
    }

    /// Merge another ViewedArea into this one
    func merging(with other: ViewedArea) -> ViewedArea {
        let mergedCells = cells.union(other.cells)
        return ViewedArea(cells: mergedCells, lastUpdated: Date())
    }

    /// Add a viewshed to the viewed area
    func adding(viewshed: ViewShed) -> ViewedArea {
        var newCells = cells

        for point in viewshed.visiblePoints {
            let cell = GridCell(coordinate: point.coordinate)
            newCells.insert(cell)
        }

        return ViewedArea(cells: newCells, lastUpdated: Date())
    }
}

/// Represents a grid cell for efficient storage of viewed areas
/// Using 100m x 100m cells for balance between precision and storage
struct GridCell: Codable, Hashable, Sendable {
    let gridX: Int
    let gridY: Int

    /// Size of each grid cell in meters
    static let cellSize: Double = AppConstants.Storage.gridCellSize

    /// Area of each cell in km²
    static let cellAreaKm2: Double = (cellSize * cellSize) / 1_000_000.0

    init(gridX: Int, gridY: Int) {
        self.gridX = gridX
        self.gridY = gridY
    }

    /// Create a grid cell from a coordinate
    init(coordinate: Coordinate) {
        // Convert lat/lon to approximate meters
        // This is a simplified projection, acceptable for local areas
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLon = 111_320.0 * cos(coordinate.latitude * .pi / 180)

        let x = coordinate.longitude * metersPerDegreeLon
        let y = coordinate.latitude * metersPerDegreeLat

        self.gridX = Int(floor(x / GridCell.cellSize))
        self.gridY = Int(floor(y / GridCell.cellSize))
    }

    /// Get the center coordinate of this grid cell
    var centerCoordinate: Coordinate {
        let metersPerDegreeLat = 111_320.0

        let y = (Double(gridY) + 0.5) * GridCell.cellSize
        let x = (Double(gridX) + 0.5) * GridCell.cellSize

        let latitude = y / metersPerDegreeLat
        let metersPerDegreeLon = 111_320.0 * cos(latitude * .pi / 180)
        let longitude = x / metersPerDegreeLon

        return Coordinate(latitude: latitude, longitude: longitude)
    }

    /// Get all four corner coordinates of this grid cell
    var corners: [Coordinate] {
        let metersPerDegreeLat = 111_320.0

        let minY = Double(gridY) * GridCell.cellSize
        let maxY = Double(gridY + 1) * GridCell.cellSize
        let minX = Double(gridX) * GridCell.cellSize
        let maxX = Double(gridX + 1) * GridCell.cellSize

        let minLat = minY / metersPerDegreeLat
        let maxLat = maxY / metersPerDegreeLat

        let avgLat = (minLat + maxLat) / 2
        let metersPerDegreeLon = 111_320.0 * cos(avgLat * .pi / 180)

        let minLon = minX / metersPerDegreeLon
        let maxLon = maxX / metersPerDegreeLon

        return [
            Coordinate(latitude: minLat, longitude: minLon),
            Coordinate(latitude: minLat, longitude: maxLon),
            Coordinate(latitude: maxLat, longitude: maxLon),
            Coordinate(latitude: maxLat, longitude: minLon)
        ]
    }
}
