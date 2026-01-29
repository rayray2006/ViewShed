import Foundation

/// Protocol defining viewshed data persistence capabilities
protocol ViewShedRepositoryProtocol: AnyObject {
    /// Save a viewshed calculation
    func save(viewshed: ViewShed) async throws

    /// Retrieve all viewsheds
    func fetchAll() async throws -> [ViewShed]

    /// Retrieve viewsheds within a date range
    func fetch(from startDate: Date, to endDate: Date) async throws -> [ViewShed]

    /// Retrieve viewsheds near a coordinate within a radius
    func fetch(near coordinate: Coordinate, radius: Double) async throws -> [ViewShed]

    /// Delete a viewshed by ID
    func delete(id: UUID) async throws

    /// Delete all viewsheds
    func deleteAll() async throws

    /// Get total count of viewsheds
    func count() async throws -> Int
}
