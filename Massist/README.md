# MAssist

MAssist is a SwiftUI iOS app for tracking nutrition, hydration, exercise, everyday spending, and loans in one place.

## Features

### Health tracking

- Profile setup with age, weight, height, gender, goal, and nutrition targets.
- Daily calorie, protein, carbohydrate, and fat tracking.
- Food entry through a photo scan or a typed meal description.
- Gemini nutrition analysis with a local estimate fallback for image scans.
- Editable and deletable meal timeline entries.
- Water intake tracking with configurable goals and workday reminders.
- Walking, jogging, and running workouts with route, distance, duration, pace, calories, and step count.
- Home dashboard with nutrition, hydration, steps, and finance summaries.

### Finance tracking

- Budget records for everyday purchases.
- Manual budget entries with a name and amount.
- Grocery or food bill photo uploads with Gemini receipt-total extraction.
- Daily spending total and spending history.
- Loan records with amount taken, interest rate, amount paid, remaining balance, and estimated monthly interest.
- Loan editing, deletion, and payment updates.
- Home finance snapshot showing today's spending, total amount taken, and total amount paid.

### Reports and exports

- Nutrition CSV export.
- Budget CSV export with date, name, amount, and source.
- Loans CSV export with principal, interest, payments, remaining balance, and monthly due.
- Settings action to prepare an email report addressed to the registered email address.
- Email report includes all three CSV files and a Gemini-generated summary of spending, nutrition, water, loans, and steps.
- A local report summary is used when Gemini is unavailable.

## Project structure

The Xcode project is in the `Massist` directory.

- `MassistApp.swift` - App entry point and shared `AppStore` injection.
- `Views.swift` - SwiftUI navigation, dashboards, trackers, forms, exports, and mail reporting.
- `Models 2.swift` - User, nutrition, loan, and budget record models.
- `Storage.swift` - Observable app state and UserDefaults persistence for loans and budget records.
- `DataService.swift` - Core Data operations and Gemini networking services.
- `CoreDataStack.swift` - Programmatically-created Core Data model and persistent container.
- `ManagedObjects.swift` - Core Data managed objects and model conversion helpers.
- `WorkoutTracker.swift` - Location, workout timing, and step tracking.
- `WorkoutView.swift` and `WorkoutMapView.swift` - Workout interface and route map.
- `ImagePicker.swift` - Photo library image picker.
- `MacroTargets.swift` - Nutrition target calculations.
- `WorkoutType.swift` - Workout types and SF Symbol mappings.
- `Assets.xcassets` - App colors and icons.

## Requirements

- macOS with Xcode installed.
- An iOS simulator or physical iPhone.
- A Gemini API key for AI food scans, receipt scans, typed meal analysis, motivation, and generated report summaries.
- Apple Mail configured on the device for direct email report sending.

## Run the app

1. Open `Massist/Massist.xcodeproj` in Xcode.
2. Select the `Massist` scheme.
3. Select an iOS Simulator or connected iPhone.
4. Build and run.
5. Create a profile during onboarding.
6. Add a Gemini API key in Settings if AI features are needed.

The project can also be built from the repository's `Massist` directory:

```sh
xcodebuild -project "Massist.xcodeproj" \
	-scheme Massist \
	-destination 'platform=iOS Simulator,name=iPhone 17' \
	build
```

## Permissions

MAssist requests the following permissions when the related features are used:

- Motion access for daily and workout step counts.
- Location access while using the app for workout routes and distance.
- Photo library access for meal and receipt images.
- Notifications for hydration reminders.

Workout location tracking is configured for foreground use. The app does not require background location updates to build or run.

## Data and privacy

- Profile and nutrition entries are stored locally using Core Data.
- Loans and budget records are stored locally using UserDefaults.
- The Gemini API key is stored in the local profile data and sent only with requests to the configured Gemini endpoint.
- Images are sent to Gemini only when the user starts an image analysis.
- Report generation is optional. If Mail, Gemini, or step counting is unavailable, the rest of the app remains usable.

## Known limitations

- Water intake currently stores the active intake value rather than a dated daily history, so monthly reports describe the currently recorded water value instead of a complete historical monthly total.
- Direct email sending depends on Apple Mail being configured. The app reports this condition instead of blocking other features.
- Gemini results are estimates and should not be treated as medical, nutritional, financial, or accounting advice.
