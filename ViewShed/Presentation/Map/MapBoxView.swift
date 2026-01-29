import SwiftUI
import MapboxMaps
import CoreLocation
import Combine

/// SwiftUI wrapper for MapBox MapView
struct MapBoxView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)

        // Configure MapBox manager
        context.coordinator.mapBoxManager.configure(mapView: mapView)

        // Store reference for location updates
        context.coordinator.mapView = mapView

        // Request location permission and start updates
        context.coordinator.requestLocationPermission()
        
        // Handle map taps
        context.coordinator.mapBoxManager.onTap = { coordinate in
            Task { @MainActor in
                viewModel.handleMapTap(coordinate)
            }
        }

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        // Update camera if coordinates changed OR recenter was explicitly requested
        let coordsChanged = context.coordinator.lastCenter != viewModel.mapCenter
        let recenterRequested = context.coordinator.lastRecenterRequestId != viewModel.recenterRequestId

        if coordsChanged || recenterRequested {
            context.coordinator.mapBoxManager.moveCamera(
                to: viewModel.mapCenter,
                zoom: viewModel.mapZoom,
                pitch: viewModel.mapPitch,
                animated: true
            )
            context.coordinator.lastCenter = viewModel.mapCenter
            context.coordinator.lastRecenterRequestId = viewModel.recenterRequestId
        }

        // Update viewed area visibility
        context.coordinator.mapBoxManager.setViewedAreaVisible(viewModel.showViewedAreas)

        // Update viewed area opacity
        context.coordinator.mapBoxManager.setViewedAreaOpacity(viewModel.viewedAreaOpacity)

        // Update user location blue dot
        if let userLocation = viewModel.userLocation {
            context.coordinator.mapBoxManager.updateUserLocationMarker(coordinate: userLocation)
        }
        
        // Update selected location red pin
        if let selectedLocation = viewModel.selectedLocation {
            context.coordinator.mapBoxManager.updateSelectedLocationMarker(coordinate: selectedLocation)
        }

        // Update viewshed overlay
        if let geoJSON = viewModel.viewshedGeoJSON,
           context.coordinator.lastViewshedGeoJSON != geoJSON {
            context.coordinator.mapBoxManager.addViewedAreaSource(geoJSON: geoJSON)
            context.coordinator.lastViewshedGeoJSON = geoJSON
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CLLocationManagerDelegate {
        let viewModel: MapViewModel
        let mapBoxManager = MapBoxManager()
        var lastCenter: Coordinate?
        var lastRecenterRequestId: UUID?
        var lastViewshedGeoJSON: String?
        weak var mapView: MapView?
        private let locationManager = CLLocationManager()

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }

        func requestLocationPermission() {
            let status = locationManager.authorizationStatus
            switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                startLocationUpdates()
            case .denied, .restricted:
                Task { @MainActor in
                    viewModel.errorMessage = "Location access denied. Enable in Settings > Privacy > Location Services."
                }
            @unknown default:
                break
            }
        }

        func startLocationUpdates() {
            locationManager.startUpdatingLocation()
            Task { @MainActor in
                viewModel.isTrackingLocation = true
            }
        }

        // MARK: - CLLocationManagerDelegate

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                startLocationUpdates()
            case .denied, .restricted:
                Task { @MainActor in
                    viewModel.errorMessage = "Location access denied. Enable in Settings."
                }
            default:
                break
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            Task { @MainActor in
                viewModel.updateUserLocation(location)
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Location error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    MapBoxView(viewModel: MapViewModel())
}
