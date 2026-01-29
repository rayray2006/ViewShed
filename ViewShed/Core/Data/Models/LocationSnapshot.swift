import Foundation
import SwiftData

/// SwiftData model for persisting location history
@Model
final class LocationSnapshot {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var horizontalAccuracy: Double
    var verticalAccuracy: Double
    var timestamp: Date
    var hasCalculatedViewshed: Bool

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        timestamp: Date,
        hasCalculatedViewshed: Bool = false
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.hasCalculatedViewshed = hasCalculatedViewshed
    }

    /// Convert to domain Coordinate model
    func toCoordinate() -> Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }
}
