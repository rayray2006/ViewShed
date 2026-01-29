import Foundation
import CoreLocation
import Combine

/// Protocol defining location tracking capabilities
protocol LocationServiceProtocol: AnyObject {
    /// Publisher for location updates
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }

    /// Publisher for authorization status changes
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }

    /// Current location (if available)
    var currentLocation: CLLocation? { get }

    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus { get }

    /// Start tracking location with specified accuracy
    func startTracking(accuracy: CLLocationAccuracy)

    /// Stop tracking location
    func stopTracking()

    /// Request location permissions
    func requestAuthorization()

    /// Set up geofencing with specified distance threshold
    func setupGeofencing(distanceThreshold: Double)
}
