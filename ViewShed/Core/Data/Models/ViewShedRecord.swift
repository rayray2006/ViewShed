import Foundation
import SwiftData

/// SwiftData model for persisting viewshed calculations
@Model
final class ViewShedRecord {
    @Attribute(.unique) var id: UUID
    var observerLatitude: Double
    var observerLongitude: Double
    var observerElevation: Double
    var observerHeight: Double
    var timestamp: Date
    var maxDistance: Double
    var angularResolution: Double
    var visiblePointsData: Data // Encoded array of VisiblePoint

    init(
        id: UUID,
        observerLatitude: Double,
        observerLongitude: Double,
        observerElevation: Double,
        observerHeight: Double,
        timestamp: Date,
        maxDistance: Double,
        angularResolution: Double,
        visiblePointsData: Data
    ) {
        self.id = id
        self.observerLatitude = observerLatitude
        self.observerLongitude = observerLongitude
        self.observerElevation = observerElevation
        self.observerHeight = observerHeight
        self.timestamp = timestamp
        self.maxDistance = maxDistance
        self.angularResolution = angularResolution
        self.visiblePointsData = visiblePointsData
    }

    /// Convert to domain ViewShed model
    func toDomain() throws -> ViewShed {
        let visiblePoints = try JSONDecoder().decode([VisiblePoint].self, from: visiblePointsData)
        return ViewShed(
            id: id,
            observerLocation: Coordinate(latitude: observerLatitude, longitude: observerLongitude),
            observerElevation: observerElevation,
            observerHeight: observerHeight,
            timestamp: timestamp,
            maxDistance: maxDistance,
            angularResolution: angularResolution,
            visiblePoints: visiblePoints
        )
    }

    /// Create from domain ViewShed model
    static func from(viewshed: ViewShed) throws -> ViewShedRecord {
        let visiblePointsData = try JSONEncoder().encode(viewshed.visiblePoints)
        return ViewShedRecord(
            id: viewshed.id,
            observerLatitude: viewshed.observerLocation.latitude,
            observerLongitude: viewshed.observerLocation.longitude,
            observerElevation: viewshed.observerElevation,
            observerHeight: viewshed.observerHeight,
            timestamp: viewshed.timestamp,
            maxDistance: viewshed.maxDistance,
            angularResolution: viewshed.angularResolution,
            visiblePointsData: visiblePointsData
        )
    }
}
