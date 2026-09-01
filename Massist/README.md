# MAssist (iOS) - Production-ready Frontend

This workspace contains a SwiftUI production-stage restructure of the Btracker iOS app.

Main highlights:

- Registration & onboarding
- Calorie & protein target calculation
- Gemini-powered image-based food scan with a local fallback
- Core Data persistence (programmatically-created model)
- Organized source layout and a minimal Xcode project (`Btracker.xcodeproj`)

Project layout (key files):

- `BtrackerApp.swift` — App entry, injects `AppStore` and Core Data context
- `Models 2.swift` — lightweight structs used by the UI
- `CoreDataStack.swift` — programmatic Core Data model and container
- `ManagedObjects.swift` — `NSManagedObject` subclasses + mapping helpers
- `DataService.swift` — Core Data CRUD wrapper
- `Storage.swift` — `AppStore` observable object backed by `DataService`
- `Views.swift`, `ImagePicker.swift`, `MacroTargets.swift` — UI and helpers

New folder layout (production-ready):

- `Sources/App` — app entry and app-level files
- `Sources/Models` — model definitions
- `Sources/Views` — SwiftUI views
- `Sources/Services` — data & persistence (Core Data stack, data service)
- `Sources/Utils` — helpers (image picker, calculator)
- `Resources` — assets and storyboards
- `Tests` — unit tests

How to open and run

1. Open Xcode and choose Open... then select `Btracker.xcodeproj` in this folder.
2. Select a simulator (iPhone 13 / iOS 15+ recommended) and Run.

Notes & next steps

- The Core Data model is created programmatically to keep the repo portable without an `.xcdatamodeld` file. It defines `CDUserProfile` and `CDFoodEntry` entities.
- Gemini API key configuration is available in the Settings tab; image analysis falls back to a local estimate when Gemini is unavailable.
- I added a minimal pbxproj that references the source files; for complex app configurations (multiple targets, app groups, push entitlements) we'll expand the project file in Xcode.
