# Speedwatch

A speed reading app for iOS and Apple Watch that lets you read EPUB books using the Spritz reading technique - one word at a time at customizable speeds.

## Features

### iOS App
- **EPUB Import**: Import EPUB books from Files app or other sources
- **Book Library**: Manage your collection of books with cover art and progress tracking
- **Spritz Reader**: Read one word at a time with optimal recognition point (ORP) highlighting
- **Customizable Speed**: Adjust reading speed from 100 to 1000 words per minute
- **Progress Tracking**: Automatically saves your position in each book
- **iCloud Sync**: Reading positions sync across devices via CloudKit

### Apple Watch App
- **Synced Library**: Access your books from your iPhone
- **Watch Reader**: Full Spritz-style reader optimized for small screen
- **Independent Reading**: Continue reading where you left off on any device
- **Speed Controls**: Adjust reading speed on the watch
- **Real-time Sync**: Position updates sync between phone and watch

## Technical Overview

### Architecture
- **SwiftUI**: Modern declarative UI for both iOS and watchOS
- **Core Data + CloudKit**: Persistent storage with automatic cloud sync
- **WatchConnectivity**: Real-time communication between iPhone and Apple Watch
- **EPUB Parser**: Custom parser to extract text and metadata from EPUB files

### Key Components

#### iOS
- `SpeedwatchApp.swift`: Main app entry point
- `LibraryView.swift`: Book library with grid layout
- `ReaderView.swift`: Spritz-style reader with playback controls
- `SettingsView.swift`: App settings and configuration

#### watchOS
- `SpeedwatchWatchApp.swift`: Watch app entry point
- `WatchContentView.swift`: Book list for watch
- `WatchReaderView.swift`: Compact Spritz reader for watch
- `WatchBookManager.swift`: Manages book data on watch

#### Shared
- `Book.swift`: Core Data model for books
- `DataController.swift`: Core Data stack with CloudKit integration
- `EPUBParser.swift`: EPUB file parsing and text extraction
- `WatchConnectivityManager.swift`: Handles sync between devices

### How Spritz Reading Works

Spritz reading displays one word at a time, with the Optimal Recognition Point (ORP) highlighted in red. The ORP is typically:
- 1st character for words with 1-5 letters
- 2nd character for words with 6-9 letters
- 3rd character for words with 10-13 letters
- 4th character for words with 14+ letters

This technique allows readers to focus on a single point and eliminate eye movement, potentially increasing reading speed.

## Setup Instructions

### Prerequisites
- Xcode 14.0 or later
- iOS 16.0+ deployment target
- watchOS 9.0+ for watch app
- Apple Developer account (for CloudKit and WatchConnectivity)

### Configuration

1. **Open in Xcode**:
   - This project needs to be opened in Xcode to build
   - The file structure is set up for manual Xcode project creation

2. **Create Xcode Project**:
   ```
   - Create new iOS App project named "Speedwatch"
   - Add watchOS target named "Speedwatch Watch App"
   - Set bundle identifier: com.speedwatch.ios (iOS), com.speedwatch.watchos (Watch)
   - Add files from the appropriate directories
   ```

3. **Configure CloudKit**:
   - In Xcode, select your project
   - Go to Signing & Capabilities
   - Add "iCloud" capability
   - Enable CloudKit
   - Create container: iCloud.com.speedwatch.library

4. **Configure Entitlements**:
   - Use the provided `.entitlements` files
   - Ensure iCloud containers are properly configured

5. **Add Core Data Model**:
   - Add the Speedwatch.xcdatamodeld to your project
   - Ensure it's included in both iOS and Watch targets (for shared access)

6. **Set Up Watch Connectivity**:
   - Ensure WatchConnectivity framework is linked
   - Configure proper App Groups if needed

### Building and Running

1. **iOS App**:
   - Select "Speedwatch" scheme
   - Choose iOS device or simulator
   - Build and run (⌘R)

2. **Watch App**:
   - Select "Speedwatch Watch App" scheme
   - Choose Watch simulator paired with iOS simulator
   - Build and run (⌘R)

### File Structure
```
Speedwatch/
├── iOS/
│   ├── SpeedwatchApp.swift
│   ├── Info.plist
│   ├── Speedwatch.entitlements
│   └── Views/
│       ├── ContentView.swift
│       ├── LibraryView.swift
│       ├── ReaderView.swift
│       └── SettingsView.swift
├── Watch/
│   ├── SpeedwatchWatchApp.swift
│   ├── Info.plist
│   ├── Views/
│   │   ├── WatchContentView.swift
│   │   └── WatchReaderView.swift
│   ├── Models/
│   │   └── WatchBookManager.swift
│   └── Services/
│       └── WatchConnectivityManager+Watch.swift
└── Shared/
    ├── Models/
    │   └── Book.swift
    ├── Persistence/
    │   ├── DataController.swift
    │   └── Speedwatch.xcdatamodeld/
    └── Services/
        ├── EPUBParser.swift
        └── WatchConnectivityManager.swift
```

## Usage

### Importing Books
1. Tap the "+" button in the library
2. Select an EPUB file from Files or another app
3. The book will be imported, parsed, and added to your library

### Reading
1. Tap a book in the library to open the reader
2. Tap play/pause to start/stop reading
3. Use skip buttons to jump forward/backward by 10 words
4. Adjust speed with +/- buttons or slider
5. Your position is auto-saved

### Syncing to Watch
1. Ensure iPhone and Watch are paired and connected
2. Books automatically appear on watch
3. Open a book on watch to start reading
4. Position syncs automatically between devices

## Customization

### Reading Speed Presets
- **Slow (100-200 WPM)**: Comfortable for difficult material
- **Average (250-300 WPM)**: Normal reading pace
- **Fast (400-500 WPM)**: Quick reading for familiar content
- **Speed (600+ WPM)**: Advanced speed reading

### Settings
- Default reading speed
- Auto-sync toggle
- Watch connection status

## Known Limitations

1. **EPUB Format**: Currently supports basic EPUB 2/3 format. Complex formatting, images in text, and tables may not display correctly
2. **File Size**: Large books (50MB+) may take longer to sync to watch
3. **Watch Storage**: Limited storage on watch - sync only books you're actively reading
4. **Network**: CloudKit sync requires internet connection for initial setup

## Future Enhancements

- [ ] PDF support
- [ ] Reading statistics and analytics
- [ ] Customizable themes and colors
- [ ] Adjustable ORP calculation
- [ ] Bookmarks and highlights
- [ ] Export reading progress data
- [ ] Complication for Apple Watch
- [ ] Focus modes integration

## Privacy

- All books are stored locally on your device
- Reading positions sync via your personal iCloud account
- No data is sent to third-party servers
- No analytics or tracking

## License

MIT License - feel free to modify and distribute

## Credits

Inspired by the Spritz speed reading technique. Built with SwiftUI and modern Apple frameworks.
