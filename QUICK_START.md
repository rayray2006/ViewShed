# Quick Start Guide

## ✅ What's Been Completed

### Phase 1: Foundation & Setup ✅
- Complete project structure with Clean Architecture
- All domain models (Coordinate, ViewShed, ViewedArea)
- SwiftData models for persistence
- Service protocols defined
- MapBox token configured in Info.plist

### Phase 2: MapBox Integration ✅
- **MapBoxManager.swift** - MapBox SDK interface with 3D terrain
- **MapBoxView.swift** - SwiftUI wrapper for MapView
- **MapViewModel.swift** - State management for map
- **MapControlsView.swift** - Map controls overlay
- **ContentView.swift** - Updated to show map

## 🚀 Running the App

### Step 1: Open in Xcode
```bash
cd /Users/rayray/ViewShed
./setup.sh
```

Or manually:
```bash
open ViewShed.xcodeproj
```

### Step 2: Wait for Package Resolution
When Xcode opens, it will automatically:
- Resolve Swift Package Manager dependencies
- Download MapboxMaps (~2 minutes)
- Download Turf-swift

You'll see progress in the top toolbar.

### Step 3: Add Source Files to Target

The project file needs to include all Swift files in the build. In Xcode:

1. Select `ViewShed.xcodeproj` in the Project Navigator (left sidebar)
2. Select the `ViewShed` target
3. Click the `Build Phases` tab
4. Expand `Compile Sources`
5. Click the `+` button
6. Select all `.swift` files from the file list:
   - Core/Domain/Models/* (3 files)
   - Core/Domain/Protocols/* (4 files)
   - Core/Data/Models/* (4 files)
   - Infrastructure/MapBox/* (1 file)
   - Presentation/Map/* (3 files)
   - Utilities/Constants/* (1 file)
7. Click "Add"

**Tip:** You can multi-select by holding ⌘ (Command) while clicking

### Step 4: Build and Run

1. Select a simulator from the scheme menu (top bar)
   - iPhone 15 Pro or newer (iOS 17.0+)
   - Or use a physical device running iOS 17.0+

2. Press ⌘R or click the Play button

3. When prompted, allow location permissions:
   - Select "Allow While Using App" or "Allow Always"

### Step 5: Verify Map Display

You should see:
- ✅ 3D terrain map with MapBox Outdoors style
- ✅ Your location (blue dot) if on device, or SF bay area if simulator
- ✅ Map controls on the right side:
  - Location button (blue)
  - Eye icon (green) - toggle viewed areas
  - Reset button (gray)
- ✅ Coordinates at bottom if location is available

## 🐛 Troubleshooting

### "No such module 'MapboxMaps'"
**Solution:** Wait for package resolution to complete, then:
1. Product → Clean Build Folder (Shift+⌘K)
2. Product → Build (⌘B)

### "Missing MapBox token"
**Solution:** Check `ViewShed/Info.plist` line 64 has your token:
```xml
<string>pk.eyJ1Ijoi...</string>
```

### Source files not compiling
**Solution:** Make sure all .swift files are added to target (see Step 3 above)

### Location not working
**Solution:**
- Simulator: Features → Location → Custom Location → Set coordinates
- Device: Settings → Privacy → Location Services → ViewShed → While Using

## 📁 Project Files Created

```
ViewShed/
├── ViewShed.xcodeproj/          # Xcode project
├── Package.swift                 # Swift Package Manager config
├── setup.sh                      # Setup script
├── README.md                     # Full documentation
├── QUICK_START.md               # This file
└── ViewShed/
    ├── ViewShedApp.swift         # App entry point ✅
    ├── ContentView.swift         # Main view with map ✅
    ├── Info.plist                # Config with MapBox token ✅
    ├── Assets.xcassets/          # App icons
    ├── Core/
    │   ├── Domain/
    │   │   ├── Models/
    │   │   │   ├── Coordinate.swift       ✅
    │   │   │   ├── ViewShed.swift         ✅
    │   │   │   └── ViewedArea.swift       ✅
    │   │   └── Protocols/
    │   │       ├── LocationServiceProtocol.swift        ✅
    │   │       ├── ElevationProviderProtocol.swift      ✅
    │   │       ├── ViewShedRepositoryProtocol.swift     ✅
    │   │       └── ViewedAreaRepositoryProtocol.swift   ✅
    │   └── Data/
    │       └── Models/
    │           ├── ViewShedRecord.swift       ✅
    │           ├── ViewedAreaEntity.swift     ✅
    │           ├── LocationSnapshot.swift     ✅
    │           └── ElevationTile.swift        ✅
    ├── Infrastructure/
    │   └── MapBox/
    │       └── MapBoxManager.swift            ✅
    ├── Presentation/
    │   └── Map/
    │       ├── MapBoxView.swift               ✅
    │       ├── MapViewModel.swift             ✅
    │       └── MapControlsView.swift          ✅
    └── Utilities/
        └── Constants/
            └── AppConstants.swift             ✅
```

## 🎯 What's Next

### Phase 3: Location Tracking (Next)
- LocationService implementation
- Geofencing (trigger calculations every 100m)
- Background location support

### Phase 4: Elevation Data Provider
- Terrain-RGB tile fetching from MapBox
- RGB-to-elevation decoder
- LRU cache implementation

### Phase 5: Viewshed Algorithm
- R3 ray casting algorithm
- Line-of-sight calculation
- Background processing

Would you like me to continue with Phase 3?

## 📞 Need Help?

Common issues:
1. **Packages not resolving**: File → Packages → Reset Package Caches
2. **Build errors**: Clean build folder (Shift+⌘K), then build (⌘B)
3. **Simulator slow**: Use iPhone 15 Pro simulator, not older models
4. **Missing files**: Make sure all .swift files are in Compile Sources

## 🎉 Success Checklist

- [ ] Xcode opened project
- [ ] Packages resolved (MapboxMaps, Turf)
- [ ] All .swift files added to target
- [ ] Build successful (⌘B)
- [ ] App runs (⌘R)
- [ ] Map displays with 3D terrain
- [ ] Location permission granted
- [ ] Blue dot shows user location

Once you see the map with terrain, Phase 2 is complete! 🎊
