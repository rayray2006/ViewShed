import Foundation
import CoreLocation

/// Represents a geographic coordinate with latitude and longitude
struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(clLocation: CLLocationCoordinate2D) {
        self.latitude = clLocation.latitude
        self.longitude = clLocation.longitude
    }

    /// Convert to CLLocationCoordinate2D for CoreLocation compatibility
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Calculate distance to another coordinate in meters
    func distance(to other: Coordinate) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }

    /// Calculate bearing to another coordinate in degrees (0-360)
    func bearing(to destination: Coordinate) -> Double {
        let lat1 = latitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lon2 = destination.longitude * .pi / 180

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)

        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Calculate destination coordinate given distance and bearing
    func destination(distance: Double, bearing: Double) -> Coordinate {
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let brng = bearing * .pi / 180

        let earthRadius = 6371000.0 // meters
        let angularDistance = distance / earthRadius

        let lat2 = asin(sin(lat1) * cos(angularDistance) +
                       cos(lat1) * sin(angularDistance) * cos(brng))
        let lon2 = lon1 + atan2(sin(brng) * sin(angularDistance) * cos(lat1),
                               cos(angularDistance) - sin(lat1) * sin(lat2))

        return Coordinate(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }
}
