# Speedwatch – Setup Guide

## Why Xcode can't build the project yet

The repository contains Swift source files but **no `.xcodeproj`** — that's what Xcode needs to know how to build the app.  
The easiest way to generate it is with **XcodeGen**, a free CLI tool.

---

## Step 1 – Install XcodeGen

If you have Homebrew:

```bash
brew install xcodegen
```

No Homebrew? Install it directly:

```bash
mint install yonaskolb/XcodeGen
```

Or download a release binary from https://github.com/yonaskolb/XcodeGen/releases

---

## Step 2 – Generate the Xcode project

Open Terminal, `cd` to the folder that contains `project.yml`, then run:

```bash
xcodegen generate
```

This creates `Speedwatch.xcodeproj` in the same folder.  
Open it in Xcode:

```bash
open Speedwatch.xcodeproj
```

---

## Step 3 – Configure Signing

1. In Xcode, click the **Speedwatch** project in the left sidebar.
2. Select the **Speedwatch** target → **Signing & Capabilities**.
3. Check **Automatically manage signing** and choose your Apple ID / Team.
4. Repeat for the **SpeedwatchWatchApp** target.

---

## Step 4 – Enable iCloud / CloudKit

1. Still in **Signing & Capabilities**, click **+ Capability**.
2. Add **iCloud**.
3. Under **Services**, check **CloudKit**.
4. Under **Containers**, click **+** and add: `iCloud.com.speedwatch.library`  
   (or use the default one Xcode offers — just keep it consistent).

> **Note:** CloudKit requires a paid Apple Developer account ($99/year).  
> If you only want to test locally (no sync), you can skip this step and remove  
> `NSPersistentCloudKitContainer` references from `DataController.swift`.

---

## Step 5 – Build & Run

### iOS App
1. Select the **Speedwatch** scheme (top toolbar).
2. Choose an iPhone simulator or your physical iPhone.
3. Press **⌘R**.

### Apple Watch App
1. Select the **SpeedwatchWatchApp** scheme.
2. Choose a Watch simulator **paired** with an iOS simulator  
   *(Window → Devices and Simulators to check pairing)*.
3. Press **⌘R**.

---

## Adding books

1. Tap **+** in the library.
2. Pick any `.epub` file from Files.
3. The app parses it and adds it to your library.

Free EPUB books are available at [Project Gutenberg](https://www.gutenberg.org).

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `xcodegen: command not found` | Re-run the install command, or restart Terminal |
| "No signing certificate" error | Sign in to Xcode with your Apple ID (Xcode → Settings → Accounts) |
| CloudKit errors at launch | Sign into iCloud on the simulator/device, or disable CloudKit (see Step 4 note) |
| Watch app not appearing | The Watch simulator must be paired with the iOS simulator you're running |
| Build error: missing package | Xcode should auto-resolve SPM packages; if not, File → Packages → Resolve |

---

## Re-generating after code changes

If you add new files, run `xcodegen generate` again — it's fast and non-destructive.  
Your signing settings are preserved in `project.yml`.

---

## File structure reference

```
Speedwatch/
├── project.yml               ← XcodeGen config (generates the .xcodeproj)
├── Speedwatch/
│   ├── iOS/                  ← iPhone app source (iOS target only)
│   │   ├── SpeedwatchApp.swift
│   │   ├── EPUBParser.swift
│   │   ├── Info.plist
│   │   ├── Speedwatch.entitlements
│   │   └── Views/
│   ├── Watch/                ← Watch app source (watchOS target only)
│   │   ├── SpeedwatchWatchApp.swift
│   │   ├── Info.plist
│   │   ├── Views/
│   │   ├── Models/
│   │   └── Services/
│   └── Shared/               ← Code compiled into both targets
│       ├── Models/
│       │   ├── BookInfo.swift   (Codable struct – shared)
│       │   └── Book.swift       (NSManagedObject – iOS only via project.yml)
│       ├── Persistence/
│       │   ├── DataController.swift
│       │   └── Speedwatch.xcdatamodeld/
│       └── Services/
│           ├── WatchConnectivityManager.swift
│           └── NotificationNames.swift
```
