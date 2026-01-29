import Foundation
import CoreLocation

/// Calculates viewshed using R3 ray casting algorithm
final class ViewshedCalculator {

    // MARK: - Configuration

    struct Configuration {
        /// Maximum distance to check visibility (meters)
        let maxDistance: Double

        /// Angular resolution in degrees (e.g., 1.0 = 360 rays)
        let angularResolution: Double

        /// Distance between elevation samples along each ray (meters)
        let sampleInterval: Double

        /// Observer height above ground (meters)
        let observerHeight: Double

        /// Whether to account for Earth curvature
        let accountForCurvature: Bool

        /// Earth radius in meters
        let earthRadius: Double

        static let `default` = Configuration(
            maxDistance: AppConstants.ViewShed.maxDistance,
            angularResolution: AppConstants.ViewShed.angularResolution,
            sampleInterval: AppConstants.Elevation.samplingResolution,
            observerHeight: AppConstants.ViewShed.observerHeight,
            accountForCurvature: true,
            earthRadius: AppConstants.ViewShed.earthRadius
        )
    }

    // MARK: - Result Types

    /// A point that was determined to be visible
    struct VisiblePoint {
        let coordinate: Coordinate
        let distance: Double
        let bearing: Double
        let elevation: Float
    }

    /// Result of a viewshed calculation
    struct ViewshedResult {
        let observerLocation: Coordinate
        let observerElevation: Float
        let visiblePoints: [VisiblePoint]
        let calculationTime: TimeInterval
        let configuration: Configuration
    }

    // MARK: - Properties

    private let elevationProvider = ElevationProvider.shared
    private let config: Configuration

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.config = configuration
    }

    // MARK: - Main Calculation

    /// Calculate viewshed from a given location
    /// - Parameters:
    ///   - location: Observer location
    ///   - progress: Optional callback for progress updates (0.0 to 1.0)
    /// - Returns: ViewshedResult containing all visible points
    func calculateViewshed(
        from location: Coordinate,
        progress: ((Double) -> Void)? = nil
    ) async -> ViewshedResult {
        let startTime = Date()

        // Get observer elevation
        let observerGroundElevation = await elevationProvider.elevation(at: location) ?? 0
        let observerElevation = observerGroundElevation + Float(config.observerHeight)

        // Calculate number of rays based on angular resolution
        let numRays = Int(360.0 / config.angularResolution)

        // Process rays concurrently
        var allVisiblePoints: [VisiblePoint] = []
        let lock = NSLock()

        await withTaskGroup(of: [VisiblePoint].self) { group in
            for rayIndex in 0..<numRays {
                group.addTask {
                    let bearing = Double(rayIndex) * self.config.angularResolution
                    let points = await self.castRay(
                        from: location,
                        observerElevation: observerElevation,
                        bearing: bearing
                    )
                    return points
                }
            }

            var completed = 0
            for await rayPoints in group {
                lock.lock()
                allVisiblePoints.append(contentsOf: rayPoints)
                completed += 1
                lock.unlock()

                progress?(Double(completed) / Double(numRays))
            }
        }

        let calculationTime = Date().timeIntervalSince(startTime)

        return ViewshedResult(
            observerLocation: location,
            observerElevation: observerElevation,
            visiblePoints: allVisiblePoints,
            calculationTime: calculationTime,
            configuration: config
        )
    }

    // MARK: - Ray Casting

    /// Cast a single ray and return visible points along it
    private func castRay(
        from origin: Coordinate,
        observerElevation: Float,
        bearing: Double
    ) async -> [VisiblePoint] {
        var visiblePoints: [VisiblePoint] = []
        var maxAngle: Double = -.infinity

        // Number of samples along the ray
        let numSamples = Int(config.maxDistance / config.sampleInterval)

        // Pre-calculate all sample coordinates
        var sampleCoordinates: [Coordinate] = []
        sampleCoordinates.reserveCapacity(numSamples)

        for i in 1...numSamples {
            let distance = Double(i) * config.sampleInterval
            let point = origin.destination(distance: distance, bearing: bearing)
            sampleCoordinates.append(point)
        }

        // Batch fetch elevations for efficiency
        let elevations = await elevationProvider.elevations(at: sampleCoordinates)

        // Process each sample
        for i in 0..<numSamples {
            let distance = Double(i + 1) * config.sampleInterval
            let point = sampleCoordinates[i]

            guard let groundElevation = elevations[i] else {
                continue
            }

            // Adjust for Earth curvature if enabled
            var adjustedElevation = groundElevation
            if config.accountForCurvature {
                let curvatureDrop = earthCurvatureDrop(distance: distance)
                adjustedElevation -= Float(curvatureDrop)
            }

            // Calculate angle from observer to this point
            let elevationDiff = Double(adjustedElevation) - Double(observerElevation)
            let angle = atan2(elevationDiff, distance)

            // Point is visible if angle is greater than max angle so far
            if angle > maxAngle {
                maxAngle = angle

                visiblePoints.append(VisiblePoint(
                    coordinate: point,
                    distance: distance,
                    bearing: bearing,
                    elevation: groundElevation
                ))
            }
        }

        return visiblePoints
    }

    // MARK: - Earth Curvature

    /// Calculate elevation drop due to Earth's curvature at a given distance
    /// Uses the approximation: drop ≈ d² / (2 * R)
    private func earthCurvatureDrop(distance: Double) -> Double {
        return (distance * distance) / (2 * config.earthRadius)
    }

    // MARK: - Grid Conversion

    /// Convert visible points to a grid of cells
    func pointsToGrid(
        _ result: ViewshedResult
    ) -> Set<GridCell> {
        var cells: Set<GridCell> = []

        for point in result.visiblePoints {
            let cell = GridCell(coordinate: point.coordinate)
            cells.insert(cell)
        }

        return cells
    }
}

// MARK: - GeoJSON Export

extension ViewshedCalculator {
    /// Convert grid cells to GeoJSON for map display
    static func gridToGeoJSON(_ cells: Set<GridCell>) -> String {
        var features: [String] = []

        for cell in cells {
            let corners = cell.corners
            // Ensure we have 4 corners (SW, SE, NE, NW)
            guard corners.count == 4 else { continue }
            
            // Construct polygon closing the loop (SW -> SE -> NE -> NW -> SW)
            let sw = corners[0]
            let se = corners[1]
            let ne = corners[2]
            let nw = corners[3]
            
            let feature = """
            {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[\
            [\(sw.longitude),\(sw.latitude)],\
            [\(se.longitude),\(se.latitude)],\
            [\(ne.longitude),\(ne.latitude)],\
            [\(nw.longitude),\(nw.latitude)],\
            [\(sw.longitude),\(sw.latitude)]]]}}
            """
            features.append(feature)
        }

        return "{\"type\":\"FeatureCollection\",\"features\":[\(features.joined(separator: ","))]}"
    }
}
