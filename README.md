## VocaTo (iOS 16+, SwiftUI + Core Data)

VocaTo is a vocabulary learning app for English → Korean with a primary brand color `#368D28`. It uses SwiftUI (MVVM), Core Data (local only), daily reminders, simple spaced repetition (1/3/7 days), CSV import/export, stats, and a basic home-screen widget.

### Tech
- iOS 16+
- SwiftUI, MVVM
- Core Data (local persistence)
- UserNotifications (daily reminder, user-selected time)
- CSV import/export (SwiftUI FileImporter/FileExporter)
- WidgetKit (basic “Word of the Day” placeholder)

### Color & Style
- Primary Green: `#368D28`
- AccentColor aligned to primary
- Glassmorphism: `.ultraThinMaterial` surfaces with blur and subtle strokes

---

## Getting Started

This repository uses XcodeGen to generate the Xcode project.

1) Install tools (Homebrew + XcodeGen):

```bash
brew install xcodegen
```

2) Generate the Xcode project:

```bash
cd "$(dirname "$0")"
xcodegen generate
```

3) Open and run:

```bash
open VocaTo.xcodeproj
```

Select an iOS Simulator and build/run.

---

## Project Structure

- `project.yml` — XcodeGen spec
- `VocaTo/` — App sources
  - `App.swift` — App entry
  - `Persistence.swift` — Core Data stack
  - `Model/` — Core Data model and entities
  - `ViewModels/` — MVVM ViewModels
  - `Views/` — SwiftUI screens and components
  - `Resources/Assets.xcassets` — Colors, AppIcon
- `VocaToWidget/` — WidgetKit extension (basic placeholder)
- `VocaToTests/` — Unit tests

---

## Core Features

- Words: term (EN), meaning (KR), memo, synonyms
- Study: Flashcards + Multiple Choice
- Speed Control: Slider to control auto-advance
- SRS: Simple intervals 1/3/7 days; wrong resets streak/interval
- Notifications: Daily reminder at user-selected time
- Stats: Daily study count + accuracy
- CSV: Import/Export via Files app
- Widget: Basic card placeholder (upgrade to App Group later for shared data)

---

## Notes

- Bundle IDs in `project.yml` are placeholders (`com.vocato.app`, `com.vocato.app.widget`). Change as needed.
- Widget currently shows placeholder content. To show real data from Core Data, configure an App Group and move the store to the shared container.


