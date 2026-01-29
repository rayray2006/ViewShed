import Foundation
import SwiftUI
import Combine
import CoreLocation

/// ViewModel for map view state management
@MainActor
final class MapViewModel: ObservableObject {
    // MARK: - Published Properties

    // Initialize with test location (Half Dome) for simulator testing
    @Published var userLocation: Coordinate? = AppConstants.Map.defaultCenter
    @Published var selectedLocation: Coordinate?
    @Published var isTrackingLocation = false
    @Published var showViewedAreas = true
    @Published var viewedAreaOpacity: Double = AppConstants.Map.overlayOpacity
    @Published var mapCenter: Coordinate = AppConstants.Map.defaultCenter
    @Published var mapZoom: Double = AppConstants.Map.defaultZoom
    @Published var mapPitch: Double = AppConstants.Map.defaultPitch
    @Published var errorMessage: String?
    @Published var recenterRequestId: UUID = UUID() // Triggers camera update
    @Published var isCalculatingViewshed = false
    @Published var viewshedProgress: Double = 0
    @Published var viewshedGeoJSON: String?
    @Published var lastCalculationTime: TimeInterval?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let viewshedCalculator = ViewshedCalculator()

    // MARK: - Initialization

    init() {
        // Set initial selected location to default center
        selectedLocation = AppConstants.Map.defaultCenter
        setupObservers()
    }
    
    // MARK: - Map Interaction
    
    func handleMapTap(_ coordinate: Coordinate) {
        selectedLocation = coordinate
        // Clear previous viewshed when location changes
        viewshedGeoJSON = nil
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe location tracking changes
        $isTrackingLocation
            .sink { [weak self] isTracking in
                if isTracking {
                    self?.startLocationTracking()
                } else {
                    self?.stopLocationTracking()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Location Tracking

    func startLocationTracking() {
        // Will be implemented in Phase 3 with LocationService
        print("Location tracking started")
    }

    func stopLocationTracking() {
        // Will be implemented in Phase 3 with LocationService
        print("Location tracking stopped")
    }

    func updateUserLocation(_ location: CLLocation) {
        let newCoord = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        // Skip Bay Area coordinates (simulator default) - use test location instead
        let isBayArea = location.coordinate.latitude > 37.2 && location.coordinate.latitude < 38.0
            && location.coordinate.longitude > -123.0 && location.coordinate.longitude < -121.5

        if !isBayArea {
            userLocation = newCoord
        }
        // Otherwise keep the test location (Half Dome)
    }

    // MARK: - Camera Control

    func moveToUserLocation() {
        guard let location = userLocation else {
            errorMessage = "User location not available"
            return
        }
        mapCenter = location
        recenterRequestId = UUID() // Force camera update even if coordinates are same
    }

    func moveToCoordinate(_ coordinate: Coordinate, zoom: Double? = nil) {
        mapCenter = coordinate
        if let zoom = zoom {
            mapZoom = zoom
        }
    }

    func resetCamera() {
        mapCenter = AppConstants.Map.defaultCenter
        mapZoom = AppConstants.Map.defaultZoom
        mapPitch = AppConstants.Map.defaultPitch
        recenterRequestId = UUID() // Force camera update
    }

    // MARK: - Viewed Area Control

    func toggleViewedAreas() {
        showViewedAreas.toggle()
    }

    func updateViewedAreaOpacity(_ opacity: Double) {
        viewedAreaOpacity = max(0.0, min(1.0, opacity))
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    // MARK: - Viewshed Calculation

    func calculateViewshed() {
        guard let location = selectedLocation ?? userLocation else {
            errorMessage = "Please select a location on the map"
            return
        }

        guard !isCalculatingViewshed else {
            return // Already calculating
        }

        isCalculatingViewshed = true
        viewshedProgress = 0

        Task {
            let result = await viewshedCalculator.calculateViewshed(from: location) { [weak self] progress in
                Task { @MainActor in
                    self?.viewshedProgress = progress
                }
            }

            // Convert to grid and GeoJSON
            let cells = viewshedCalculator.pointsToGrid(result)
            let geoJSON = ViewshedCalculator.gridToGeoJSON(cells)

            await MainActor.run {
                self.viewshedGeoJSON = geoJSON
                self.lastCalculationTime = result.calculationTime
                self.isCalculatingViewshed = false
                print("Viewshed complete: \(result.visiblePoints.count) points, \(cells.count) cells, \(String(format: "%.2f", result.calculationTime))s")
            }
        }
    }
}
