import Foundation
import MapboxMaps
import CoreLocation
import UIKit
import Turf

/// Manager class for MapBox SDK integration
final class MapBoxManager {
    private weak var mapView: MapView?
    
    /// Callback when map is tapped
    var onTap: ((Coordinate) -> Void)?

    /// Initialize MapBox with a map view
    func configure(mapView: MapView) {
        self.mapView = mapView
        setupMap()
        setupGestures()
    }
    
    /// Setup map gestures
    private func setupGestures() {
        guard let mapView = mapView else { return }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let point = sender.location(in: mapView)
        let coordinate = mapView.mapboxMap.coordinate(for: point)
        
        let coord = Coordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        onTap?(coord)
    }

    /// Setup map with Outdoors style and 3D terrain
    private func setupMap() {
        guard let mapView = mapView else { return }

        // Set Outdoors style (similar to AllTrails)
        mapView.mapboxMap.loadStyle(.outdoors) { [weak self] error in
            if let error = error {
                print("Error loading map style: \(error)")
            } else {
                self?.enable3DTerrain()
                // Add initial user location marker at test location
                self?.updateUserLocationMarker(coordinate: AppConstants.Map.defaultCenter)
            }
        }

        // Configure camera for 3D view
        let cameraOptions = CameraOptions(
            center: AppConstants.Map.defaultCenter.clCoordinate,
            zoom: AppConstants.Map.defaultZoom,
            pitch: AppConstants.Map.defaultPitch
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)

        // Enable user location
        enableLocationTracking()

        // Configure ornaments
        mapView.ornaments.options.scaleBar.visibility = .visible
        mapView.ornaments.options.compass.visibility = .visible

        // Hide MapBox logo (find and hide the subviews)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for subview in mapView.subviews {
                if String(describing: type(of: subview)).contains("Logo") ||
                   String(describing: type(of: subview)).contains("Attribution") {
                    subview.isHidden = true
                }
            }
        }
    }

    /// Enable 3D terrain layer
    private func enable3DTerrain() {
        guard let mapView = mapView else { return }

        // Add terrain source
        var terrainSource = RasterDemSource(id: "mapbox-dem")
        terrainSource.url = "mapbox://mapbox.terrain-rgb"
        terrainSource.tileSize = 512
        terrainSource.maxzoom = 14

        do {
            try mapView.mapboxMap.addSource(terrainSource)

            // Configure terrain
            var terrain = Terrain(sourceId: "mapbox-dem")
            terrain.exaggeration = .constant(1.5) // Slight exaggeration for visibility

            try mapView.mapboxMap.setTerrain(terrain)
        } catch {
            print("Error adding terrain: \(error)")
        }
    }

    /// Enable location tracking
    private func enableLocationTracking() {
        guard let mapView = mapView else { return }

        // Disable built-in puck - we use our own custom blue dot
        mapView.location.options.puckType = .none
    }

    /// Move camera to a specific coordinate
    func moveCamera(to coordinate: Coordinate, zoom: Double? = nil, pitch: Double? = nil, animated: Bool = true) {
        guard let mapView = mapView else { return }

        let cameraOptions = CameraOptions(
            center: coordinate.clCoordinate,
            zoom: zoom ?? mapView.mapboxMap.cameraState.zoom,
            pitch: pitch ?? mapView.mapboxMap.cameraState.pitch
        )

        if animated {
            mapView.camera.ease(to: cameraOptions, duration: 1.0)
        } else {
            mapView.mapboxMap.setCamera(to: cameraOptions)
        }
    }

    /// Add a GeoJSON source for viewed areas
    func addViewedAreaSource(geoJSON: String) {
        guard let mapView = mapView else { return }

        // Remove existing source if present
        try? mapView.mapboxMap.removeLayer(withId: "viewed-area-layer")
        try? mapView.mapboxMap.removeSource(withId: "viewed-area-source")

        // Add GeoJSON source
        var source = GeoJSONSource(id: "viewed-area-source")
        source.data = .string(geoJSON)

        do {
            try mapView.mapboxMap.addSource(source)

            // Add fill layer for viewed areas
            var fillLayer = FillLayer(id: "viewed-area-layer", source: "viewed-area-source")
            fillLayer.fillColor = .constant(StyleColor(UIColor(hex: AppConstants.Map.overlayColor) ?? .green))
            fillLayer.fillOpacity = .constant(AppConstants.Map.overlayOpacity)

            try mapView.mapboxMap.addLayer(fillLayer)
        } catch {
            print("Error adding viewed area source: \(error)")
        }
    }

    /// Update viewed area visibility
    func setViewedAreaVisible(_ visible: Bool) {
        guard let mapView = mapView else { return }

        do {
            var fillLayer = try mapView.mapboxMap.layer(withId: "viewed-area-layer", type: FillLayer.self)
            fillLayer.visibility = visible ? .constant(.visible) : .constant(.none)
            try mapView.mapboxMap.updateLayer(withId: "viewed-area-layer", type: FillLayer.self) { layer in
                layer.visibility = fillLayer.visibility
            }
        } catch {
            print("Error updating viewed area visibility: \(error)")
        }
    }

    /// Update viewed area opacity
    func setViewedAreaOpacity(_ opacity: Double) {
        guard let mapView = mapView else { return }

        do {
            try mapView.mapboxMap.updateLayer(withId: "viewed-area-layer", type: FillLayer.self) { layer in
                layer.fillOpacity = .constant(opacity)
            }
        } catch {
            print("Error updating viewed area opacity: \(error)")
        }
    }

    /// Update user location blue dot
    func updateUserLocationMarker(coordinate: Coordinate) {
        guard let mapView = mapView else { return }

        let sourceId = "user-location-source"
        let layerId = "user-location-layer"
        let pulseLayerId = "user-location-pulse-layer"

        // Create point geometry
        let point = Point(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))

        do {
            // Check if source exists
            if mapView.mapboxMap.sourceExists(withId: sourceId) {
                // Update existing source
                try mapView.mapboxMap.updateGeoJSONSource(withId: sourceId, geoJSON: .geometry(.point(point)))
            } else {
                // Create new source and layers
                var source = GeoJSONSource(id: sourceId)
                source.data = .geometry(.point(point))
                try mapView.mapboxMap.addSource(source)

                // Add pulse/glow circle (larger, semi-transparent)
                var pulseLayer = CircleLayer(id: pulseLayerId, source: sourceId)
                pulseLayer.circleRadius = .constant(20)
                pulseLayer.circleColor = .constant(StyleColor(UIColor.systemBlue.withAlphaComponent(0.3)))
                pulseLayer.circleStrokeWidth = .constant(0)
                try mapView.mapboxMap.addLayer(pulseLayer)

                // Add main blue dot
                var circleLayer = CircleLayer(id: layerId, source: sourceId)
                circleLayer.circleRadius = .constant(8)
                circleLayer.circleColor = .constant(StyleColor(UIColor.systemBlue))
                circleLayer.circleStrokeColor = .constant(StyleColor(UIColor.white))
                circleLayer.circleStrokeWidth = .constant(3)
                try mapView.mapboxMap.addLayer(circleLayer)
            }
        } catch {
            print("Error updating user location marker: \(error)")
        }
    }
    
    /// Update selected location marker (Red Pin)
    func updateSelectedLocationMarker(coordinate: Coordinate) {
        guard let mapView = mapView else { return }

        let sourceId = "selected-location-source"
        let layerId = "selected-location-layer"

        // Create point geometry
        let point = Point(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))

        do {
            // Check if source exists
            if mapView.mapboxMap.sourceExists(withId: sourceId) {
                // Update existing source
                try mapView.mapboxMap.updateGeoJSONSource(withId: sourceId, geoJSON: .geometry(.point(point)))
            } else {
                // Create new source and layers
                var source = GeoJSONSource(id: sourceId)
                source.data = .geometry(.point(point))
                try mapView.mapboxMap.addSource(source)

                // Add red pin marker
                var circleLayer = CircleLayer(id: layerId, source: sourceId)
                circleLayer.circleRadius = .constant(10)
                circleLayer.circleColor = .constant(StyleColor(UIColor.systemRed))
                circleLayer.circleStrokeColor = .constant(StyleColor(UIColor.white))
                circleLayer.circleStrokeWidth = .constant(2)
                try mapView.mapboxMap.addLayer(circleLayer)
            }
        } catch {
            print("Error updating selected location marker: \(error)")
        }
    }

    /// Get current camera position
    var cameraState: CameraState? {
        mapView?.mapboxMap.cameraState
    }

    /// Get current map bounds
    var visibleBounds: CoordinateBounds? {
        mapView?.mapboxMap.coordinateBounds(for: mapView!.bounds)
    }
}
