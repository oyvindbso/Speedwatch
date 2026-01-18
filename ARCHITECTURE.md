# Speedwatch - Architecture Documentation

## Overview

Speedwatch is a dual-platform app (iOS and watchOS) that implements speed reading using the Spritz technique. The architecture emphasizes:

- **Shared code** between iOS and Watch where possible
- **CloudKit sync** for seamless cross-device experience
- **WatchConnectivity** for real-time updates between paired devices
- **Core Data** for persistent local storage

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         iCloud                              │
│                  (CloudKit Container)                        │
└────────────┬────────────────────────────────┬───────────────┘
             │                                │
             │ CloudKit Sync                  │ CloudKit Sync
             │                                │
┌────────────▼──────────────┐    ┌───────────▼──────────────┐
│      iOS App              │    │    Apple Watch App       │
│  ┌─────────────────────┐  │    │  ┌────────────────────┐  │
│  │   SwiftUI Views     │  │    │  │  SwiftUI Views     │  │
│  └─────────┬───────────┘  │    │  └─────────┬──────────┘  │
│  ┌─────────▼───────────┐  │◄───┼──┤ WatchConnectivity  │  │
│  │  ViewModels/State   │  │    │  │                    │  │
│  └─────────┬───────────┘  │    │  └─────────┬──────────┘  │
│  ┌─────────▼───────────┐  │    │  ┌─────────▼──────────┐  │
│  │  Core Data Stack    │  │    │  │  WatchBookManager  │  │
│  │  (with CloudKit)    │  │    │  │  (UserDefaults)    │  │
│  └─────────────────────┘  │    │  └────────────────────┘  │
└───────────────────────────┘    └─────────────────────────┘
        Watch Connectivity ◄─────────────►
```

## Data Flow

### Book Import (iOS Only)

```
1. User selects EPUB file
   ↓
2. EPUBParser extracts metadata and text
   ↓
3. Book entity created in Core Data
   ↓
4. Words saved to JSON file in Documents
   ↓
5. CloudKit automatically syncs Book entity
   ↓
6. WatchConnectivity sends book list to Watch
```

### Reading on iOS

```
1. User opens book
   ↓
2. Words loaded from JSON file
   ↓
3. SpritzWordView displays current word
   ↓
4. Timer advances position based on WPM
   ↓
5. Position saved to Core Data (periodic)
   ↓
6. CloudKit syncs position update
   ↓
7. WatchConnectivity notifies Watch
```

### Reading on Watch

```
1. User opens book from synced list
   ↓
2. Words requested from iPhone via WatchConnectivity
   ↓
3. Words cached locally on Watch
   ↓
4. SpritzWordView displays current word
   ↓
5. Position updates sent to iPhone
   ↓
6. iPhone updates Core Data
   ↓
7. CloudKit syncs across devices
```

## Core Components

### 1. Data Layer

#### Core Data Model (iOS)
- **Entity**: `Book`
- **Attributes**:
  - `id`: UUID (primary key)
  - `title`: String
  - `author`: String?
  - `coverImageData`: Binary Data?
  - `filePath`: String (relative to Documents)
  - `dateAdded`: Date
  - `lastOpened`: Date?
  - `currentPosition`: Int64 (current word index)
  - `totalWords`: Int64

#### DataController
- Manages NSPersistentCloudKitContainer
- Handles CloudKit sync configuration
- Provides save/fetch operations
- Singleton pattern for app-wide access

#### WatchBookManager (Watch)
- Lightweight storage for Watch
- Uses UserDefaults for book list
- Caches word arrays in Documents
- No Core Data on Watch (reduces complexity)

### 2. Sync Layer

#### CloudKit Integration
- **Container**: `iCloud.com.speedwatch.library`
- **What syncs**: Book entities (metadata + position)
- **What doesn't sync**: Word arrays (too large, sent via WatchConnectivity)
- **Merge policy**: Property object trump (latest write wins)
- **History tracking**: Enabled for conflict resolution

#### WatchConnectivity
- **Message types**:
  - `books`: Send book list to Watch
  - `bookContent`: Send word array for specific book
  - `positionUpdate`: Bi-directional position sync
  - `requestBooks`: Watch requests book list
  - `requestBookContent`: Watch requests words for book

- **Transfer modes**:
  - `sendMessage`: Interactive mode (app in foreground)
  - `updateApplicationContext`: Background mode (app in background)

### 3. Business Logic

#### EPUBParser
- **Input**: EPUB file URL
- **Process**:
  1. Unzip EPUB (EPUB is a ZIP file)
  2. Parse container.xml to find content.opf
  3. Parse content.opf for metadata and spine
  4. Extract title, author, cover image
  5. Read HTML files in reading order
  6. Strip HTML tags and extract words
- **Output**: EPUBContent (metadata + word array)

#### Spritz Algorithm
- **Word Display**: One word at a time
- **ORP (Optimal Recognition Point)**: Highlighted character
  - 1-5 chars: 2nd character (index 1)
  - 6-9 chars: 3rd character (index 2)
  - 10-13 chars: 4th character (index 3)
  - 14+ chars: 5th character (index 4)
- **Timing**: `interval = 60 / WPM` seconds per word
- **Timer**: Scheduled timer advances word index

### 4. Presentation Layer

#### iOS Views

**ContentView**
- TabView with Library and Settings
- Root navigation structure

**LibraryView**
- Grid of BookCard views
- File importer for EPUB
- Handles book import flow

**ReaderView**
- Main reading interface
- SpritzWordView for word display
- Playback controls
- Speed slider
- Progress indicator
- Position auto-save

**SettingsView**
- Default WPM configuration
- Sync settings
- Watch connection status

#### Watch Views

**WatchContentView**
- List of books (simplified)
- Empty state when no books

**WatchReaderView**
- Compact Spritz reader
- Essential controls only
- Speed adjustment buttons
- Progress indicator

## Design Patterns

### 1. MVVM (Model-View-ViewModel)
- **Model**: Core Data entities, BookInfo struct
- **View**: SwiftUI views
- **ViewModel**: @StateObject/@ObservedObject managers

### 2. Singleton
- `DataController.shared`
- `WatchConnectivityManager.shared`
- Ensures single source of truth

### 3. Observer Pattern
- `@Published` properties
- `NotificationCenter` for cross-component communication
- Core Data change notifications

### 4. Repository Pattern
- DataController abstracts Core Data
- WatchBookManager abstracts Watch storage
- Views don't directly access persistence

## State Management

### iOS App State
- **@StateObject**: Long-lived objects (DataController, WatchConnectivity)
- **@ObservedObject**: Passed objects (Book entities)
- **@State**: View-local state (isPlaying, currentIndex)
- **@AppStorage**: UserDefaults-backed (readingSpeed)
- **@Environment**: Dependency injection (managedObjectContext)

### Watch App State
- **@StateObject**: WatchBookManager, WatchConnectivity
- **@State**: View-local state
- **@AppStorage**: Shared preferences
- **UserDefaults**: Persistent storage (simpler than Core Data)

## Performance Considerations

### 1. Memory Management
- **Words array**: Loaded on-demand, not kept in Core Data
- **Cover images**: Stored as compressed JPEG data
- **Watch cache**: Limited to actively reading books

### 2. Sync Optimization
- **Incremental sync**: Only position changes, not full book
- **Batching**: Position saves batched (every 50 words)
- **Throttling**: WatchConnectivity updates throttled

### 3. UI Responsiveness
- **Timer**: Invalidated when stopping to prevent leaks
- **Main thread**: UI updates on main queue
- **Background**: File operations can be background

## Security & Privacy

### 1. Data Storage
- **Local**: Documents directory (app sandbox)
- **Cloud**: User's private CloudKit database
- **Watch**: Paired device only (encrypted communication)

### 2. File Access
- **Security-scoped resources**: Properly acquired for imported files
- **Cleanup**: Temporary EPUB extraction cleaned up

### 3. Privacy
- **No analytics**: No tracking code
- **No third-party**: No external SDKs
- **User data**: Stays in user's iCloud account

## Testing Strategy

### Unit Tests
- EPUBParser logic
- ORP calculation
- Word extraction
- Data model validation

### Integration Tests
- Core Data save/fetch
- CloudKit sync
- WatchConnectivity message passing

### UI Tests
- Book import flow
- Reader playback
- Settings changes
- Watch book selection

## Future Architecture Improvements

### 1. Modularization
- Extract EPUB parser to Swift Package
- Separate sync logic into module
- Create shared UI components package

### 2. Performance
- Lazy loading for very large books
- Streaming word display
- Background sync processing

### 3. Features
- Offline-first architecture
- Conflict resolution UI
- Advanced caching strategies
- Multi-book download queue

### 4. Scalability
- Support for very large libraries (1000+ books)
- Pagination in book list
- Search and filtering
- Collections/categories

## Dependencies

### Apple Frameworks
- **SwiftUI**: UI framework
- **CoreData**: Local persistence
- **CloudKit**: Cloud sync
- **WatchConnectivity**: Device communication
- **UniformTypeIdentifiers**: File type handling
- **Foundation**: Core utilities

### Third-Party
- **None**: Pure Apple stack for reliability and App Store compliance

## Build Configuration

### Targets
1. **Speedwatch (iOS)**: Main iPhone app
2. **Speedwatch Watch App (watchOS)**: Apple Watch companion

### Capabilities Required
- **iCloud**: CloudKit container
- **Background Modes** (optional): Background sync
- **App Groups** (optional): Enhanced data sharing

### Deployment Targets
- **iOS**: 16.0+
- **watchOS**: 9.0+
- **Swift**: 5.7+

## Debugging

### Logging Points
- EPUB parsing errors
- CloudKit sync conflicts
- WatchConnectivity failures
- Core Data save failures

### Console Keywords
- "Error importing book"
- "Error loading words"
- "Error sending"
- "CloudKit sync"

### Common Issues
1. **CloudKit not syncing**: Check iCloud account, container ID
2. **Watch not connecting**: Check WCSession activation
3. **Words not loading**: Check Documents directory path
4. **Position not saving**: Check Core Data context
