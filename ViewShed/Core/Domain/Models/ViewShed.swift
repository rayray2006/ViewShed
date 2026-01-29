import Foundation

/// Represents a calculated viewshed from a specific observer location
struct ViewShed: Codable, Identifiable, Sendable {
    let id: UUID
    let observerLocation: Coordinate
    let observerElevation: Double // meters above sea level
    let observerHeight: Double // height above ground (e.g., eye level ~1.7m)
    let timestamp: Date
    let maxDistance: Double // meters
    let angularResolution: Double // degrees between rays
    let visiblePoints: [VisiblePoint]

    init(
        id: UUID = UUID(),
        observerLocation: Coordinate,
        observerElevation: Double,
        observerHeight: Double = 1.7,
        timestamp: Date = Date(),
        maxDistance: Double,
        angularResolution: Double,
        visiblePoints: [VisiblePoint]
    ) {
        self.id = id
        self.observerLocation = observerLocation
        self.observerElevation = observerElevation
        self.observerHeight = observerHeight
        self.timestamp = timestamp
        self.maxDistance = maxDistance
        self.angularResolution = angularResolution
        self.visiblePoints = visiblePoints
    }

    /// Total area visible in square kilometers
    var visibleArea: Double {
        // Approximate calculation based on visible points
        let cellArea = 100.0 * 100.0 // 100m x 100m grid cells in square meters
        let totalSquareMeters = Double(visiblePoints.count) * cellArea
        return totalSquareMeters / 1_000_000.0 // Convert to km²
    }
}

/// Represents a single visible point from the observer location
struct VisiblePoint: Codable, Hashable, Sendable {
    let coordinate: Coordinate
    let distance: Double // meters from observer
    let bearing: Double // degrees from observer
    let elevation: Double // meters above sea level

    init(coordinate: Coordinate, distance: Double, bearing: Double, elevation: Double) {
        self.coordinate = coordinate
        self.distance = distance
        self.bearing = bearing
        self.elevation = elevation
    }
}
