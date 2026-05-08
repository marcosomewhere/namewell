# Namewell – Batch Rename Tool for macOS

A native macOS 14+ SwiftUI application for batch renaming files using natural-language commands.

## Setup

Build and test from the repository root:

```sh
swift build
swift test
```

Run the app through Xcode:

```sh
xcodebuild -project Namewell.xcodeproj -scheme Namewell -configuration Debug -derivedDataPath .build/xcode build
open -n .build/xcode/Build/Products/Debug/Namewell.app
```

If the Xcode project needs to be regenerated, run:

```sh
python3 generate_xcodeproj.py
```

## Architecture

```
UI Layer (SwiftUI Views)
    └── RenameViewModel (@MainActor, ObservableObject)
            ├── CommandParser      (pure: String → [RenameRule])
            ├── RenameEngine       (pure: [RenameRule] × [RenameItem] → [String])
            ├── RenameValidator    (pure + fs existence check)
            ├── FileLoadingService (fs read: URL → [RenameItem])
            ├── FileRenameService  (fs write: [RenameItem] → RenameOperation)
            └── UndoManagerService (stack of RenameOperation)
```

## Supported Commands

| Command | Example |
|---------|---------|
| `remove <text>` | `remove IMG_` |
| `replace <old> with <new>` | `replace " " with "_"` |
| `add prefix <text>` | `add prefix 2024_` |
| `add suffix <text>` | `add suffix _final` |
| `add index` | `add index` → appends 01, 02, … |
| `add date` | `add date` → appends yyyy-MM-dd |
| `lowercase` | `lowercase` |
| `uppercase` | `uppercase` |
| `clean filename` | `clean filename` |

Combine with `and`: `remove IMG_ and add index`

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘O | Open folder |
| ⌘↩ | Rename |
| ⌘Z | Undo last rename |

## Localization

Supports: English · Deutsch · Français · Polski
