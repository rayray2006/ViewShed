import Foundation

/// Protocol defining viewed area data persistence capabilities
protocol ViewedAreaRepositoryProtocol: AnyObject {
    /// Get the complete cumulative viewed area
    func getViewedArea() async throws -> ViewedArea

    /// Add a viewshed to the viewed area
    func addViewshed(_ viewshed: ViewShed) async throws

    /// Get grid cells within a bounding box
    func getCells(in boundingBox: BoundingBox) async throws -> Set<GridCell>

    /// Check if a coordinate has been viewed
    func isViewed(coordinate: Coordinate) async throws -> Bool

    /// Get statistics about viewed areas
    func getStatistics() async throws -> ViewedAreaStatistics

    /// Clear all viewed area data
    func clearAll() async throws
}

/// Represents a geographic bounding box
struct BoundingBox: Codable, Sendable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    init(minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    /// Create a bounding box from a center coordinate and radius
    static func from(center: Coordinate, radius: Double) -> BoundingBox {
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLon = 111_320.0 * cos(center.latitude * .pi / 180)

        let latDelta = radius / metersPerDegreeLat
        let lonDelta = radius / metersPerDegreeLon

        return BoundingBox(
            minLatitude: center.latitude - latDelta,
            maxLatitude: center.latitude + latDelta,
            minLongitude: center.longitude - lonDelta,
            maxLongitude: center.longitude + lonDelta
        )
    }

    /// Check if a coordinate is within this bounding box
    func contains(_ coordinate: Coordinate) -> Bool {
        return coordinate.latitude >= minLatitude &&
               coordinate.latitude <= maxLatitude &&
               coordinate.longitude >= minLongitude &&
               coordinate.longitude <= maxLongitude
    }
}

/// Statistics about viewed areas
struct ViewedAreaStatistics: Codable, Sendable {
    let totalAreaKm2: Double
    let totalCells: Int
    let firstViewed: Date?
    let lastViewed: Date?
    let totalViewsheds: Int

    init(
        totalAreaKm2: Double,
        totalCells: Int,
        firstViewed: Date?,
        lastViewed: Date?,
        totalViewsheds: Int
    ) {
        self.totalAreaKm2 = totalAreaKm2
        self.totalCells = totalCells
        self.firstViewed = firstViewed
        self.lastViewed = lastViewed
        self.totalViewsheds = totalViewsheds
    }
}
