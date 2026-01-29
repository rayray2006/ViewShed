import Foundation

/// Protocol defining elevation data retrieval capabilities
protocol ElevationProviderProtocol: AnyObject {
    /// Get elevation for a single coordinate
    /// - Parameter coordinate: The coordinate to query
    /// - Returns: Elevation in meters above sea level, or nil if unavailable
    func elevation(at coordinate: Coordinate) async throws -> Double?

    /// Get elevations for multiple coordinates in batch
    /// - Parameter coordinates: Array of coordinates to query
    /// - Returns: Dictionary mapping coordinates to elevations
    func elevations(at coordinates: [Coordinate]) async throws -> [Coordinate: Double]

    /// Pre-cache elevation data for a region
    /// - Parameters:
    ///   - center: Center coordinate of the region
    ///   - radius: Radius in meters around the center
    func precache(center: Coordinate, radius: Double) async throws

    /// Clear elevation cache
    func clearCache()
}
