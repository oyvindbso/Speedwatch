# Speedwatch - Feature Specifications

## Core Features

### 1. EPUB Import & Management

#### Import Capabilities
- ✅ Import from Files app
- ✅ Import from other apps via share sheet
- ✅ Drag and drop support (iPad)
- ✅ Automatic metadata extraction
- ✅ Cover image extraction
- ✅ Title and author detection

#### Library Management
- ✅ Grid view of books with covers
- ✅ Sort by: Recently read, Date added, Title
- ✅ Progress tracking per book
- ✅ Search and filter (future)
- ✅ Delete books
- ✅ Edit metadata (future)

### 2. Spritz Reading Experience

#### Core Reading
- ✅ One word at a time display
- ✅ Optimal Recognition Point (ORP) highlighting
- ✅ Red highlight on key character
- ✅ Monospaced font for alignment
- ✅ Clean, distraction-free interface

#### Speed Control
- ✅ Range: 100-1000 WPM
- ✅ Slider for fine control
- ✅ +/- buttons for quick adjustment
- ✅ Real-time speed changes
- ✅ Speed persists across sessions
- ✅ Per-book speed memory (future)

#### Playback Controls
- ✅ Play/Pause toggle
- ✅ Skip forward (10 words)
- ✅ Skip backward (10 words)
- ✅ Progress bar
- ✅ Word counter (current/total)
- ✅ Jump to position (future)

### 3. Progress & Sync

#### Position Tracking
- ✅ Auto-save current position
- ✅ Resume where you left off
- ✅ Periodic saves during reading (every 50 words)
- ✅ Save on pause
- ✅ Save on app close

#### Cloud Sync
- ✅ iCloud CloudKit integration
- ✅ Automatic background sync
- ✅ Conflict resolution (latest wins)
- ✅ Privacy-preserving (user's iCloud only)
- ✅ No third-party servers

#### Cross-Device Sync
- ✅ Position syncs to all devices
- ✅ Library syncs to all devices
- ✅ Real-time updates between iPhone and Watch
- ✅ Bidirectional sync
- ✅ Offline changes queue for sync

### 4. Apple Watch App

#### Watch Features
- ✅ Standalone Spritz reader
- ✅ Book list from iPhone
- ✅ Speed controls optimized for watch
- ✅ Digital Crown support (future)
- ✅ Complications showing current book (future)

#### Watch Connectivity
- ✅ Automatic book list sync
- ✅ On-demand book content transfer
- ✅ Position updates in real-time
- ✅ Works when iPhone is locked
- ✅ Continues when iPhone out of range (cached)

### 5. Settings & Customization

#### Reading Settings
- ✅ Default reading speed
- ✅ Speed guide with recommendations
- ✅ Theme selection (future)
- ✅ Font customization (future)
- ✅ ORP offset adjustment (future)

#### Sync Settings
- ✅ Auto-sync toggle
- ✅ Watch connection status
- ✅ Sync frequency (future)
- ✅ Manual sync trigger (future)

## Feature Details

### Spritz Algorithm Implementation

The Optimal Recognition Point (ORP) is calculated based on word length:

| Word Length | ORP Position | Example |
|-------------|--------------|---------|
| 1-5 chars   | 2nd char (index 1) | "hello" → "h**e**llo" |
| 6-9 chars   | 3rd char (index 2) | "reading" → "re**a**ding" |
| 10-13 chars | 4th char (index 3) | "incredibly" → "inc**r**edibly" |
| 14+ chars   | 5th char (index 4) | "extraordinarily" → "extr**a**ordinarily" |

### Speed Recommendations

Based on research and user feedback:

- **100-150 WPM**: Learning or difficult material
- **150-200 WPM**: Comfortable, relaxed reading
- **200-250 WPM**: Casual reading
- **250-300 WPM**: Average reader speed
- **300-400 WPM**: Fast reading
- **400-500 WPM**: Advanced speed reading
- **500-700 WPM**: Professional speed reading
- **700-1000 WPM**: Scanning/skimming (comprehension may decrease)

### EPUB Support

#### Supported Features
- ✅ EPUB 2.0 format
- ✅ EPUB 3.0 format
- ✅ UTF-8 text encoding
- ✅ Basic HTML formatting
- ✅ Chapter navigation (future)
- ✅ Table of contents (future)

#### Not Supported (Currently)
- ❌ DRM-protected EPUBs
- ❌ Fixed-layout EPUBs
- ❌ Interactive EPUBs
- ❌ Audio/video embedded content
- ❌ Complex tables (text extracted but not formatted)
- ❌ Mathematical formulas (MathML)

### Progress Tracking

Progress is calculated as:
```
Progress = CurrentWordIndex / TotalWords
```

Displayed as:
- Percentage (0-100%)
- Progress bar (visual)
- Word count (e.g., "1,523 / 45,678")
- Estimated time remaining (future)

### Data Storage

#### iOS Storage
- **Books**: Core Data + CloudKit
- **Words**: JSON files in Documents directory
- **Covers**: Binary data in Core Data
- **Settings**: UserDefaults + iCloud Key-Value store

#### Watch Storage
- **Books metadata**: UserDefaults
- **Currently reading words**: Cached JSON in Documents
- **Settings**: Shared via WatchConnectivity

## Performance Specifications

### Target Metrics
- **Book import**: < 5 seconds for average EPUB (2MB)
- **Word loading**: < 1 second for any book
- **Sync latency**: < 2 seconds for position updates
- **UI responsiveness**: 60 FPS during reading
- **Memory usage**: < 100MB during reading
- **Watch transfer**: < 30 seconds for average book

### Limits
- **Max book size**: 50MB EPUB
- **Max library size**: 500 books (practical limit)
- **Max word count**: 500,000 words per book
- **Watch cache**: 5 books maximum recommended

## Accessibility

### Planned Features
- ⏳ VoiceOver support
- ⏳ Dynamic Type support
- ⏳ High contrast mode
- ⏳ Reduce motion support
- ⏳ Color blind friendly modes

### Current Status
- ✅ Standard SwiftUI accessibility
- ✅ Semantic views
- ⏳ Accessibility labels
- ⏳ Accessibility hints
- ⏳ Testing with accessibility tools

## Privacy & Security

### Data Privacy
- ✅ No user tracking
- ✅ No analytics collection
- ✅ No third-party SDKs
- ✅ Local-first architecture
- ✅ User's iCloud only

### Security
- ✅ Sandboxed file storage
- ✅ Security-scoped resource access
- ✅ Encrypted iCloud storage
- ✅ Encrypted Watch communication
- ✅ No external network requests

## Future Enhancements

### Phase 2 Features
- [ ] PDF support
- [ ] Bookmarks and highlights
- [ ] Reading statistics dashboard
- [ ] Daily reading goals
- [ ] Reading streaks
- [ ] Focus mode integration

### Phase 3 Features
- [ ] Collections and categories
- [ ] Tags and labels
- [ ] Advanced search
- [ ] Notes and annotations
- [ ] Export reading data
- [ ] Reading insights (comprehension tests)

### Phase 4 Features
- [ ] Social features (optional)
- [ ] Book recommendations
- [ ] Reading clubs
- [ ] Achievements and badges
- [ ] Widgets (iOS & Watch)
- [ ] Shortcuts integration

### Advanced Customization
- [ ] Custom color schemes
- [ ] Font selection
- [ ] ORP algorithm customization
- [ ] Word grouping (2-3 words)
- [ ] Adaptive speed (slows for long words)
- [ ] Punctuation pause adjustment

## Platform Requirements

### Minimum Requirements
- **iOS**: 16.0+
- **watchOS**: 9.0+
- **iCloud**: Required for sync
- **Storage**: 50MB minimum free space

### Recommended
- **iOS**: 17.0+ for best experience
- **watchOS**: 10.0+ for latest features
- **iCloud**: 200MB+ available
- **Device**: iPhone 12 or newer, Apple Watch Series 6 or newer

## Testing Coverage

### Unit Tests
- [ ] EPUB parsing
- [ ] ORP calculation
- [ ] Word extraction
- [ ] Progress calculation
- [ ] Data model validation

### Integration Tests
- [ ] Core Data operations
- [ ] CloudKit sync
- [ ] WatchConnectivity
- [ ] File import flow

### UI Tests
- [ ] Book import
- [ ] Reading flow
- [ ] Speed adjustment
- [ ] Settings changes
- [ ] Watch interaction

### Performance Tests
- [ ] Large book handling
- [ ] Memory usage
- [ ] Sync speed
- [ ] UI responsiveness
