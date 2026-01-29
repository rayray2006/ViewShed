# ViewShed iOS App

An iOS app that tracks user location and calculates viewsheds (visible terrain) from every location visited, displaying a cumulative map of all areas the user has had direct line of sight to.

## Features

- 🗺️ **3D Terrain Visualization** - Beautiful MapBox Outdoors style maps with terrain features
- 📍 **Location Tracking** - Continuous tracking with battery-efficient geofencing
- 👁️ **Viewshed Calculation** - R3 ray-casting algorithm to calculate visible terrain
- 💾 **Data Persistence** - SwiftData for efficient storage of viewed areas
- 🎯 **Grid-Based Storage** - 100m x 100m grid cells for optimal performance
- 🔄 **Background Processing** - Calculate viewsheds even when app is in background

## Architecture

Built using Clean Architecture with MVVM pattern:

- **Presentation Layer**: SwiftUI Views + ViewModels
- **Domain Layer**: Use Cases, Services, Domain Models, Protocols
- **Data Layer**: Repositories, SwiftData Models, Caching
- **Infrastructure Layer**: MapBox SDK, CoreLocation, Elevation APIs

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- MapBox account with API token

## Setup Instructions

### 1. Get MapBox API Token

1. Create a free account at [mapbox.com](https://www.mapbox.com/)
2. Go to your account page and create a new access token
3. Copy your public token

### 2. Configure the Project

1. Open `ViewShed/Info.plist`
2. Replace `YOUR_MAPBOX_PUBLIC_TOKEN_HERE` with your actual MapBox token:
   ```xml
   <key>MBXAccessToken</key>
   <string>pk.eyJ1Ijoi...</string>
   ```

### 3. Install Dependencies

The project uses Swift Package Manager. Dependencies will be resolved automatically when you open the project in Xcode:

- **MapboxMaps** (v11.0+) - 3D terrain visualization
- **Turf** (v2.0+) - Geographic calculations

To manually resolve packages:
1. Open `ViewShed.xcodeproj` in Xcode
2. Go to File → Packages → Resolve Package Versions
3. Wait for dependencies to download

### 4. Build and Run

1. Open `ViewShed.xcodeproj` in Xcode
2. Select a target device or simulator (iOS 17.0+)
3. Build and run (⌘R)
4. Grant location permissions when prompted

## Project Structure

```
ViewShed/
├── ViewShedApp.swift           # App entry point with SwiftData configuration
├── ContentView.swift            # Main view (placeholder for map)
├── Info.plist                   # App configuration and permissions
├── Core/
│   ├── Domain/                  # Business logic layer
│   │   ├── Models/              # Domain models (Coordinate, ViewShed, ViewedArea)
│   │   ├── Protocols/           # Service interfaces
│   │   ├── Services/            # Business logic services
│   │   └── UseCases/            # Application use cases
│   └── Data/                    # Data access layer
│       ├── Models/              # SwiftData models
│       ├── Repositories/        # Data repositories
│       └── Cache/               # Caching logic
├── Infrastructure/              # External services integration
│   ├── Location/                # CoreLocation wrapper
│   ├── MapBox/                  # MapBox SDK wrapper
│   └── Elevation/               # Elevation data provider
├── Presentation/                # UI layer
│   ├── Main/                    # Main app screens
│   ├── Map/                     # Map view and viewmodel
│   ├── Stats/                   # Statistics view
│   ├── History/                 # History view
│   ├── Settings/                # Settings view
│   ├── Onboarding/              # Onboarding flow
│   └── Location/                # Location viewmodel
└── Utilities/                   # Helper code
    ├── Extensions/              # Swift extensions
    └── Constants/               # App constants

```

## Key Constants

Located in `Utilities/Constants/AppConstants.swift`:

- **Viewshed Distance**: 10km default (configurable)
- **Angular Resolution**: 1 degree (360 rays)
- **Geofence Radius**: 100m between calculations
- **Grid Cell Size**: 100m x 100m
- **Cache Size**: 500MB for elevation data

## Current Implementation Status

### ✅ Phase 1: Foundation & Setup (COMPLETE)
- [x] Project structure
- [x] Domain models (Coordinate, ViewShed, ViewedArea, GridCell)
- [x] SwiftData models (ViewShedRecord, ViewedAreaEntity, LocationSnapshot, ElevationTile)
- [x] Protocols (LocationService, ElevationProvider, Repositories)
- [x] App constants
- [x] Info.plist configuration

### ⏳ Phase 2: MapBox Integration (PENDING)
- [ ] MapBoxView UIViewRepresentable wrapper
- [ ] 3D terrain configuration
- [ ] Camera controls
- [ ] MapViewModel

### ⏳ Phase 3: Location Tracking (PENDING)
- [ ] LocationService implementation
- [ ] Geofencing setup
- [ ] Background location support
- [ ] LocationViewModel

### ⏳ Phase 4: Elevation Data Provider (PENDING)
- [ ] Terrain-RGB tile fetching
- [ ] RGB-to-elevation decoder
- [ ] LRU cache implementation

### ⏳ Phase 5: Viewshed Algorithm (PENDING)
- [ ] R3 ray casting
- [ ] Line-of-sight calculation
- [ ] Background processing
- [ ] Performance optimizations

### ⏳ Phase 6: Data Visualization (PENDING)
- [ ] GeoJSON overlay
- [ ] Viewed area rendering
- [ ] Dynamic updates

### ⏳ Phase 7: Persistence (PENDING)
- [ ] ViewShedRepository
- [ ] ViewedAreaRepository
- [ ] Data merging logic

### ⏳ Phase 8: UI/UX Polish (PENDING)
- [ ] Main view
- [ ] Stats dashboard
- [ ] History view
- [ ] Settings
- [ ] Onboarding

### ⏳ Phase 9: Testing (PENDING)
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance testing

## Development Notes

### Viewshed Algorithm (R3)

The app uses the R3 (Radial Ray Casting) algorithm:

1. Cast 360-degree rays from observer position
2. Sample elevation at intervals along each ray
3. Check line-of-sight considering terrain and Earth curvature
4. Mark visible points as viewed in grid-based storage

**Performance Targets**:
- <5 seconds per viewshed calculation
- <5% battery per hour active use
- <200MB memory usage
- 60fps map rendering

### Grid-Based Storage

Instead of storing polygons, we use 100m x 100m grid cells:
- More efficient for global coverage
- Fast spatial queries
- Easy merging of new viewsheds
- Compact storage (~100MB per year typical use)

## Troubleshooting

### MapBox Token Issues
If you see "Missing MapBox token" errors:
1. Verify token is in Info.plist under `MBXAccessToken`
2. Ensure token starts with `pk.`
3. Check token has not expired on MapBox dashboard

### Location Permission Issues
If location is not working:
1. Check Info.plist has location usage descriptions
2. Verify background modes includes "location"
3. Grant "Always Allow" permission for background tracking

### Build Errors
If packages fail to resolve:
1. Delete DerivedData folder
2. File → Packages → Reset Package Caches
3. File → Packages → Resolve Package Versions

## License

MIT License - See LICENSE file for details

## Contributing

This is a personal project, but suggestions and improvements are welcome!

## Acknowledgments

- MapBox for terrain visualization
- SwiftData for data persistence
- Clean Architecture pattern by Robert C. Martin
