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
    
    // MARK: - Download Properties
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    
    // MARK: - Simulation Properties
    @Published var isSimulating = false
    private var simulationTask: Task<Void, Never>?
    private var cumulativeCells: Set<GridCell> = []

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let viewshedCalculator = ViewshedCalculator()
    private let elevationProvider = ElevationProvider.shared

    // MARK: - Initialization

    init() {
        // Set initial selected location to default center
        selectedLocation = AppConstants.Map.defaultCenter
        setupObservers()
    }
    
    // MARK: - Offline Support
    
    func downloadOfflineArea() {
        guard let location = mapCenter as Coordinate? else { return }
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0
        
        Task {
            // Download area matching calculation distance
            let success = await elevationProvider.downloadRegion(
                center: location,
                radiusMeters: AppConstants.ViewShed.maxDistance
            ) { [weak self] completed, total in
                Task { @MainActor in
                    self?.downloadProgress = Double(completed) / Double(total)
                }
            }
            
            await MainActor.run {
                self.isDownloading = false
                if success {
                    // Show success message briefly?
                    print("Offline area downloaded successfully")
                } else {
                    self.errorMessage = "Failed to download offline area"
                }
            }
        }
    }
    
    // MARK: - Map Interaction
    
    func handleMapTap(_ coordinate: Coordinate) {
        // Stop simulation if running
        if isSimulating {
            stopSimulation()
        }
        
        selectedLocation = coordinate
        // Clear previous viewshed when location changes manually
        viewshedGeoJSON = nil
        cumulativeCells.removeAll()
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
        
        // If not simulating, start fresh
        if !isSimulating {
            cumulativeCells.removeAll()
        }

        Task {
            let result = await viewshedCalculator.calculateViewshed(from: location) { [weak self] progress in
                Task { @MainActor in
                    self?.viewshedProgress = progress
                }
            }

            // Convert to grid and GeoJSON
            let cells = viewshedCalculator.pointsToGrid(result)
            
            await MainActor.run {
                if self.isSimulating {
                    self.cumulativeCells.formUnion(cells)
                } else {
                    self.cumulativeCells = cells
                }
                
                let geoJSON = ViewshedCalculator.gridToGeoJSON(self.cumulativeCells)
                self.viewshedGeoJSON = geoJSON
                self.lastCalculationTime = result.calculationTime
                self.isCalculatingViewshed = false
                print("Viewshed complete: \(result.visiblePoints.count) points, \(self.cumulativeCells.count) cumulative cells")
            }
        }
    }
    
    // MARK: - Simulation
    
    func toggleSimulation() {
        if isSimulating {
            stopSimulation()
        } else {
            startSimulation()
        }
    }
    
    private func startSimulation() {
        isSimulating = true
        cumulativeCells.removeAll() // Start fresh
        
        // Use Highway 2 path (Scenic -> Berne)
        // Generate 50 points for a smooth but reasonably fast simulation
        let path = SimulationPath.interpolatedPath(steps: 50)
        
        // Initial move to start
        if let start = path.first {
            selectedLocation = start
            mapCenter = start
            recenterRequestId = UUID()
        }
        
        simulationTask = Task {
            for coordinate in path {
                if Task.isCancelled { break }
                
                await MainActor.run {
                    self.selectedLocation = coordinate
                    // Move camera to follow
                    self.mapCenter = coordinate
                    self.recenterRequestId = UUID()
                }
                
                // Calculate viewshed
                let result = await viewshedCalculator.calculateViewshed(from: coordinate)
                let cells = viewshedCalculator.pointsToGrid(result)
                
                await MainActor.run {
                    self.cumulativeCells.formUnion(cells)
                    self.viewshedGeoJSON = ViewshedCalculator.gridToGeoJSON(self.cumulativeCells)
                }
                
                // Smooth animation: 0.2s delay
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            await MainActor.run {
                self.isSimulating = false
            }
        }
    }
    
    private func stopSimulation() {
        isSimulating = false
        simulationTask?.cancel()
        simulationTask = nil
    }
}
