# Speedwatch - Xcode Setup Guide

This guide will walk you through setting up the Speedwatch project in Xcode.

## Step-by-Step Setup

### 1. Create the Xcode Project

1. Open Xcode
2. Click "Create a new Xcode project"
3. Select "iOS" > "App"
4. Configure the project:
   - **Product Name**: Speedwatch
   - **Team**: Select your development team
   - **Organization Identifier**: com.yourname (or your preferred identifier)
   - **Bundle Identifier**: com.yourname.speedwatch
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data (check this box)
   - **Include Tests**: Optional
5. Choose a location (use this repository folder)

### 2. Add watchOS Target

1. In Xcode, click File > New > Target
2. Select "watchOS" > "Watch App for iOS App"
3. Configure:
   - **Product Name**: Speedwatch Watch App
   - **Bundle Identifier**: com.yourname.speedwatch.watchkitapp
4. Click Finish

### 3. Add Source Files

#### For iOS Target:

1. Delete the default `ContentView.swift` and `SpeedwatchApp.swift` files created by Xcode
2. Right-click on the Speedwatch folder in Xcode > Add Files to "Speedwatch"
3. Add these folders/files:
   - `Speedwatch/iOS/` (all files)
   - `Speedwatch/Shared/` (all files - make sure to select both iOS and Watch targets)
4. Ensure target membership is correct:
   - iOS files: iOS target only
   - Shared files: Both iOS and Watch targets

#### For Watch Target:

1. Delete default watch app files
2. Add files from `Speedwatch/Watch/` directory
3. Ensure Shared files are also included in Watch target

### 4. Configure Core Data

1. Delete the default `.xcdatamodeld` file created by Xcode
2. Add the `Speedwatch.xcdatamodeld` from `Shared/Persistence/`
3. Ensure it's included in both targets
4. Select the model file
5. In the File Inspector, check both "Speedwatch" and "Speedwatch Watch App" under Target Membership

### 5. Configure Signing & Capabilities

#### iOS App:

1. Select the Speedwatch project
2. Select "Speedwatch" target
3. Go to "Signing & Capabilities" tab
4. **Signing**:
   - Automatically manage signing: ✓
   - Team: Select your team

5. **Add Capabilities** (click + button):
   - **iCloud**:
     - Services: CloudKit ✓
     - Containers: Add "iCloud.com.speedwatch.library" (or use your own identifier)
   - **Background Modes** (if needed):
     - Background fetch ✓

6. **Entitlements**:
   - Use the provided `Speedwatch.entitlements` file
   - Or ensure iCloud containers match

#### Watch App:

1. Select "Speedwatch Watch App" target
2. Configure signing with same team
3. No additional capabilities needed for basic functionality

### 6. Configure Info.plist

1. Replace or merge the default Info.plist files with the provided ones:
   - `Speedwatch/iOS/Info.plist` for iOS
   - `Speedwatch/Watch/Info.plist` for Watch
2. Ensure EPUB file type is properly declared in iOS Info.plist

### 7. Add Assets

1. In the iOS target, create/use Assets.xcassets
2. Add an AppIcon (use SF Symbols "books.vertical" or design your own)
3. Add a LaunchScreen.storyboard or use default

4. In the Watch target, create Watch Assets.xcassets
5. Add Watch App Icon (required in multiple sizes)

### 8. Fix Build Issues

Common issues and solutions:

**Issue**: Missing Book entity
- **Fix**: Ensure Core Data model is in both targets

**Issue**: WatchConnectivity not found
- **Fix**: Add WatchConnectivity framework to both targets
  - Select target > Build Phases > Link Binary With Libraries > Add WatchConnectivity.framework

**Issue**: CloudKit errors
- **Fix**: Ensure you're signed in with an Apple Developer account and iCloud is configured

**Issue**: EPUB import not working
- **Fix**: Check Info.plist has correct UTImportedTypeDeclarations for EPUB

### 9. Update Bundle Identifiers

If you used different bundle identifiers:

1. In `WatchConnectivityManager.swift`:
   - Update CloudKit container identifier if changed

2. In Watch `Info.plist`:
   - Update `WKCompanionAppBundleIdentifier` to match iOS bundle ID

### 10. Configure CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container (iCloud.com.speedwatch.library)
3. The schema will be created automatically when you first run the app
4. Ensure "Development" and "Production" environments are properly configured

### 11. Test Build

1. Select the iOS scheme
2. Choose a simulator or device
3. Build (⌘B) to check for errors
4. Run (⌘R) to test the app

5. Select the Watch scheme
6. Choose a paired Watch simulator
7. Build and run

## Development Workflow

### Testing on Simulator

1. **iOS Simulator**:
   - Use File > Import to test EPUB import
   - You'll need to drag EPUB files into the simulator

2. **Watch Simulator**:
   - Must be paired with an iOS simulator
   - Use Window > Devices and Simulators to manage pairing

### Testing on Device

1. **iOS Device**:
   - Connect iPhone via USB
   - Trust computer and select device in Xcode
   - Run the app

2. **Apple Watch**:
   - Must be paired with the iPhone
   - Watch must be on same WiFi network
   - May need to enable "Enable Developer Mode on Watch" in iOS Settings

### CloudKit Testing

- **Development**: Use while testing, data is separate from production
- **Production**: Only use when ready to release
- Clear CloudKit data: CloudKit Dashboard > Data > Public/Private > Reset

## Troubleshooting

### App won't build:
- Clean Build Folder (⌘⇧K)
- Delete DerivedData: Xcode > Preferences > Locations > DerivedData > Click arrow > Delete folder
- Restart Xcode

### Watch app won't install:
- Unpair and re-pair Watch with iPhone
- Enable Developer Mode on Watch: Settings > Privacy > Developer Mode
- Check Watch has enough storage

### CloudKit sync not working:
- Sign in to iCloud on device
- Check internet connection
- Verify container identifier matches
- Check CloudKit Dashboard for errors

### EPUB import fails:
- Ensure EPUB file is valid (test with another EPUB reader)
- Check file isn't DRM-protected
- Verify Info.plist has correct EPUB type declaration

## Additional Resources

- [Apple CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

## Next Steps

After setup:

1. Test EPUB import with sample files
2. Test reading experience at various speeds
3. Test sync between iPhone and Watch
4. Customize colors, icons, and branding
5. Add additional features from README

## Support

For issues or questions:
- Check the README.md for feature documentation
- Review Apple's official documentation
- Check console logs for specific error messages
