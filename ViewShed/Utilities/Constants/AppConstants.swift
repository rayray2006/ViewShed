import Foundation
import CoreLocation

/// Application-wide constants
enum AppConstants {
    // MARK: - Viewshed Calculation Parameters
    enum ViewShed {
        /// Maximum distance for viewshed calculation in meters (3km default)
        static let maxDistance: Double = 3_000

        /// Angular resolution in degrees (1 degree = 360 rays)
        static let angularResolution: Double = 1.0

        /// Observer height above ground in meters (average eye level)
        static let observerHeight: Double = 1.7

        /// Minimum distance between viewshed calculations in meters
        static let calculationDistanceThreshold: Double = 100.0

        /// Earth radius in meters for curvature calculations
        static let earthRadius: Double = 6_371_000.0
    }

    // MARK: - Location Tracking
    enum Location {
        /// Location accuracy when app is active
        static let activeAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

        /// Location accuracy for background tracking
        static let backgroundAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters

        /// Geofencing distance threshold in meters
        static let geofenceRadius: Double = 100.0

        /// Minimum time between location updates in seconds
        static let minimumUpdateInterval: TimeInterval = 5.0
    }

    // MARK: - Elevation Data
    enum Elevation {
        /// MapBox Terrain-RGB tile zoom level (higher = more detail)
        static let tileZoomLevel: Int = 14

        /// Maximum cache size in bytes (500MB)
        static let maxCacheSize: Int = 500 * 1024 * 1024

        /// Tile cache expiration in days
        static let cacheExpirationDays: Int = 30

        /// Elevation sampling resolution in meters
        static let samplingResolution: Double = 10.0
    }

    // MARK: - Map Display
    enum Map {
        /// Default map center (Half Dome, Yosemite - great for viewshed testing)
        static let defaultCenter = Coordinate(latitude: 37.7459, longitude: -119.5332)

        /// Default map zoom level
        static let defaultZoom: Double = 12.0

        /// Default map pitch for 3D view
        static let defaultPitch: Double = 60.0

        /// Viewed area overlay opacity
        static let overlayOpacity: Double = 0.3

        /// Viewed area overlay color (hex)
        static let overlayColor: String = "#FF0000"
    }

    // MARK: - Storage
    enum Storage {
        /// Grid cell size in meters (100m x 100m)
        static let gridCellSize: Double = 100.0

        /// Maximum number of viewsheds to keep in history
        static let maxViewShedHistory: Int = 1000

        /// Enable data compression
        static let enableCompression: Bool = true
    }

    // MARK: - Performance
    enum Performance {
        /// Number of concurrent elevation fetch tasks
        static let maxConcurrentFetches: Int = 4

        /// Background queue quality of service
        static let calculationQoS: DispatchQoS = .userInitiated

        /// Enable progressive viewshed updates
        static let enableProgressiveUpdates: Bool = true

        /// Number of rays to process before updating UI
        static let progressiveUpdateInterval: Int = 45
    }

    // MARK: - API
    enum API {
        /// MapBox API base URL
        static let mapBoxBaseURL = "https://api.mapbox.com"

        /// MapBox Terrain-RGB tile URL template
        static let terrainRGBTileURL = "https://api.mapbox.com/v4/mapbox.terrain-rgb/{z}/{x}/{y}.pngraw"

        /// Request timeout in seconds
        static let requestTimeout: TimeInterval = 30.0

        /// Maximum retry attempts for failed requests
        static let maxRetryAttempts: Int = 3
    }
}
