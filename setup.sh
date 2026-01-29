#!/bin/bash

# ViewShed Setup Script
# This script helps set up the ViewShed Xcode project

echo "================================================"
echo "ViewShed iOS App - Setup"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "ViewShed.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Must run this script from the ViewShed project root"
    exit 1
fi

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    exit 1
fi

echo "✅ Found Xcode: $(xcodebuild -version | head -1)"
echo ""

# Check MapBox token
if grep -q "YOUR_MAPBOX_PUBLIC_TOKEN_HERE" ViewShed/Info.plist; then
    echo "⚠️  Warning: MapBox token not configured in Info.plist"
    echo "   Please add your token before building"
else
    echo "✅ MapBox token configured"
fi
echo ""

# Open the project in Xcode
echo "📱 Opening project in Xcode..."
echo ""
echo "Next steps in Xcode:"
echo "1. Wait for Swift Package Manager to resolve dependencies (~1-2 min)"
echo "2. Add all Swift files to the target if not already added:"
echo "   - Select ViewShed.xcodeproj in Project Navigator"
echo "   - Select ViewShed target"
echo "   - Go to Build Phases → Compile Sources"
echo "   - Click '+' and add all .swift files from the project"
echo "3. Select a simulator or device (iOS 17.0+)"
echo "4. Build and run (⌘R)"
echo ""
echo "Tip: If you see 'No such module' errors, clean build folder"
echo "     (Product → Clean Build Folder or Shift+⌘K)"
echo ""

open ViewShed.xcodeproj

echo "✅ Project opened in Xcode!"
echo ""
echo "================================================"
