# MAssist Project Summary

## Purpose

MAssist is a native SwiftUI iOS application for personal nutrition, hydration, activity, spending, and loan tracking. It is a single-target app with local-first data storage and optional Gemini AI features.

The Xcode project is located at `Massist/Massist.xcodeproj`.

## Technology Stack

- SwiftUI for the user interface.
- Core Data for the user profile and food entries.
- UserDefaults with Codable JSON for loans and budget records.
- CoreMotion `CMPedometer` for daily and workout step counts.
- CoreLocation for workout route and distance tracking.
- MapKit for the live workout map.
- PhotosUI `PHPickerViewController` for selecting meal and receipt photos.
- MessageUI for composing monthly email reports.
- UserNotifications for hydration reminders.
- UniformTypeIdentifiers and SwiftUI `FileDocument` for CSV exports.
- Gemini `generateContent` HTTP API for nutrition analysis, receipt analysis, motivation, questions, and report summaries.

## Application Startup and Navigation

### App entry point

`MassistApp` creates one shared `AppStore` and injects it into the SwiftUI environment. It also injects the Core Data view context and applies the theme selected in `AppStorage`.

Startup flow:

1. `AppStore` loads the profile, food entries, loans, and budget records.
2. If no profile exists, `ContentView` shows `LoginView`.
3. If the profile lacks age, weight, or height, `ContentView` shows `OnboardingView`.
4. Otherwise, `ContentView` shows `MainTabView`.

`MainTabView` contains these tabs:

- Home
- Diet
- Expenses
- Loans
- Activity
- Water
- Profile
- Settings

The initial selected tab is currently Diet (`selectedTab = 1`).

## Main State and Data Flow

`AppStore` is the central observable application state:

- `profile: UserProfile?`
- `loggedIn: Bool`
- `entries: [FoodEntry]`
- `loans: [Loan]`
- `budgetRecords: [BudgetRecord]`

Nutrition/profile operations go through `DataService`, which uses the programmatically-created Core Data model. Loan and budget operations are held in arrays and automatically saved to UserDefaults through `didSet`.

Important behavior:

- `addEntry` saves to Core Data before inserting into the published array.
- `updateEntry` updates Core Data and then the matching array element.
- `deleteEntry` deletes the Core Data object and then removes it from the array.
- Loan and budget mutations update the published arrays, triggering JSON persistence.
- Logout clears the in-memory profile and login state but does not clear stored profile, food, loan, or budget data.

## Models

Defined in `Core/Models.swift`.

### `GoalType`

Values:

- `maintain`
- `muscleGain`
- `weightLoss`

### `UserProfile`

Stores:

- Name and email.
- Optional gender.
- Optional age, weight in kilograms, and height in centimeters.
- Optional calorie, protein, and fat targets.
- Optional Gemini API key.

### `FoodEntry`

Stores:

- UUID.
- Date.
- Meal name.
- Calories as an integer.
- Carbohydrates, protein, and fats in grams as integers.
- `EntrySource`, either `photo` or `manual`.

### `Loan`

Stores:

- Name.
- Amount taken.
- Interest rate.
- Amount paid.

Computed values:

- `remainingBalance = max(0, amountTaken - amountPaid)`.
- `monthlyDue = remainingBalance * ((interestRate / 100) / 12)`.

Amounts and rates are clamped to non-negative values in the initializer.

### `BudgetRecord`

Stores:

- UUID.
- Date.
- Purchase name.
- Amount.
- `BudgetRecordSource`, either `receipt` or `manual`.

## Onboarding and Profile

### Login/profile creation

`LoginView` collects name, email, and gender. All three are required before creating a profile.

### Onboarding

`OnboardingView` collects:

- Age from 13 to 100.
- Weight from 30 to 250 kg.
- Height from 100 to 230 cm.
- Goal: maintain, muscle gain, or weight loss.

The values are written to the existing profile and unlock the main app.

### Profile screen

`ProfileView` lets the user:

- Edit personal details.
- Toggle custom nutrition targets.
- Save calorie, protein, and fat targets.
- Store the Gemini API key.
- Export nutrition, budget, and loan CSV files.
- Log out.

Custom targets cannot be lower than the calculated suggested minimums. The current implementation validates calories, protein, and fat, while carbohydrates are derived from calories, protein, and fat.

## Nutrition Target Calculation

Implemented by `MacroCalculator` in `Core/MacroTargets.swift`.

BMR uses the Mifflin-St Jeor equation:

- Male constant: `+5`.
- Default/female constant: `-161`.

Current implementation defaults to the female constant and does not use the stored gender to select the equation.

Target calculation:

1. Calculate BMR from weight, height, and age.
2. Multiply by `1.2` for a sedentary TDEE assumption.
3. Adjust calories and protein by goal:
   - Maintain: base TDEE and protein at `1.4 g/kg`.
   - Muscle gain: TDEE plus 300 kcal and protein at `2.0 g/kg`.
   - Weight loss: TDEE minus 500 kcal, minimum 1200 kcal, and protein at `1.6 g/kg`.
4. Set fats to approximately 25% of calories.
5. Derive carbohydrates from remaining calories:
   `carbs = max(0, (calories - protein * 4 - fats * 9) / 4)`.
6. User-supplied custom calorie, protein, or fat targets override calculated values.

If profile measurements are incomplete, fallback defaults are used: 2000 kcal, 75 g protein, and 55 g fat.

`MacroCalculator.analyzeImage` is a deterministic local fallback. It hashes image data with SHA-256 and generates an estimated 120 to 899 kcal meal with an approximate macro distribution. It is not a real image nutrition model.

## Home Screen

`HomeView` shows:

- Time-based greeting and first name.
- Nutrition streak.
- Goal badge.
- Cached daily motivational message from Gemini.
- Navigation to the nutrition assistant.
- Daily overview cards for calories, protein, fats, water, and steps.
- Money snapshot for today's spending, total loan amount taken, and total loan amount paid.

Daily nutrition totals include food entries whose date is the current calendar day.

Daily step total:

1. Check `CMPedometer.isStepCountingAvailable()`.
2. Query pedometer data from the start of the current day to now.
3. Convert `numberOfSteps` to `Int`.
4. Update `todaySteps` on the main thread.

The daily step progress ring uses a fixed 10,000-step goal.

`HomeMetricCard` uses a two-column grid. Metric titles are single-line and use a minimum scale factor. Values are also single-line, prioritized over the progress ring, and scaled down when needed so values such as `2000 kcal` do not split across lines.

## Diet Screen

`CaloriesView` combines `ScanView` and `TrackerView` in one scrollable screen.

### Meal entry methods

`ScanView` provides three mutually-exclusive modes controlled by `MealEntryMethod`:

1. Upload photo.
2. Describe meal.
3. Enter manually.

Only the selected form is visible.

### Photo meal flow

- The user selects one image with `ImagePicker`/PhotosUI.
- The image is sent to Gemini when an API key is available.
- Gemini returns meal name, calories, carbs, protein, and fats as JSON.
- If Gemini fails, a local deterministic estimate is displayed.
- The user can edit the meal name and date before saving.
- Saving creates a `FoodEntry` with source `.photo`.

### Description meal flow

- The user types a natural-language meal description.
- Gemini estimates meal name and nutrition values.
- The returned values are displayed for review.
- Saving creates a `FoodEntry` with source `.photo` because the current model only distinguishes photo and manual entry; this source value is a known semantic mismatch for description-based AI entries.

### Manual meal flow

The user enters:

- Meal name.
- Meal date.
- Calories.
- Carbohydrates.
- Protein.
- Fats.

Values must be non-negative whole numbers. Submission creates a `FoodEntry` with source `.manual`, persists it through `AppStore` and Core Data, and makes it available to the timeline and exports.

### Meal timeline

`TrackerView` shows today's entries only, sorted newest first. Each row displays:

- Meal name.
- Time.
- Calories.
- Protein, carbs, and fats.
- Source label (`Typed meal` or `Photo scan`).
- Edit and delete actions.

Editing updates nutrition values and preserves the original entry date and source. The current edit sheet does not allow changing the date.

## AI Integration

`GeminiNutritionService` is in `Core/DataService.swift`.

All requests use the Gemini `generateContent` endpoint and the API key stored in the local profile. The service supports:

- `analyze(image:apiKey:)`: food photo nutrition estimate.
- `analyzeText(description:apiKey:)`: typed meal nutrition estimate.
- `analyzeReceipt(image:apiKey:)`: receipt merchant/description and final amount.
- `motivationalQuote(apiKey:)`: one short daily motivation message.
- `generateReportSummary(prompt:apiKey:)`: health and finance report prose.

Gemini responses are expected to be JSON for nutrition and receipt operations. Nutrition number decoding accepts integer, double, or numeric string values. Markdown code fences are stripped, and text analysis additionally extracts the first JSON object.

Network requests use an ephemeral URLSession with five-minute request and resource timeouts. API failures are surfaced as user-readable messages. The Gemini key is stored locally and sent to the configured Google endpoint.

## Expenses Screen

`BudgetTrackerView` supports:

- Manual purchase entry with name, amount, and date.
- Receipt photo upload.
- Gemini receipt-total extraction.
- Review before adding a scanned receipt.
- Daily spending total.
- Recent spending list with delete support.

Manual records have source `.manual`; scanned receipts have source `.receipt`.

## Loans Screen

`LoansTrackerView` supports:

- Add loan with name, amount taken, and interest rate.
- Portfolio summary with Total Taken, Total paid, Amount pending, and Monthly due.
- Edit loan details and amount paid.
- Delete loans.
- Add payments, capped so amount paid cannot exceed amount taken.
- Loan status badges: Paid fully, Active, or Low due.
- Per-loan amount taken, monthly due, and paid values.

Loans are stored in UserDefaults as encoded JSON under `massist.loans`.

## Activity and Workout Tracking

`WorkoutView` and `WorkoutTracker` support:

- Walking, jogging, and running modes.
- Live MapKit map with user annotation and route polyline.
- Distance.
- Duration.
- Current speed.
- Average speed.
- Pace per kilometer.
- Steps.
- Estimated workout calories.
- Pause, resume, and finish actions.
- Workout summary screen.

### Location handling

`WorkoutTracker` uses `CLLocationManager` with:

- Fitness activity type.
- Best accuracy.
- Five-meter distance filter.
- Background location updates enabled.
- Background location indicator enabled.
- Always authorization request.

The Xcode project has `UIBackgroundModes = location` and location usage descriptions in the project-level build settings. A physical device must grant the required Always location permission for locked-screen tracking.

Location samples are accepted only when:

- Horizontal accuracy is non-negative and at most 25 meters.
- The sample is no more than 10 seconds old.
- The implied speed between samples is no more than 12 m/s.
- The individual jump is less than 100 meters.

Accepted samples update the route, distance, current speed, and average speed.

### Workout steps

When step counting is available, `CMPedometer.startUpdates(from: Date())` is used and the largest received step count is retained. When unavailable, steps are approximated as:

`distanceMeters / 0.75`

The approximation assumes an average stride of 0.75 meters.

### Workout calories

Calories use:

`MET * weightKg * elapsedHours`

MET is selected from workout type and average speed. The main workout screen currently passes a hard-coded weight of 70 kg, while the summary also receives a local `userWeightKg` state currently initialized to 70 kg. The profile weight is not yet wired into workout calorie calculations.

## Hydration

`WaterView` in `App/AppViews.swift` stores intake and goal in `AppStorage`:

- `waterIntakeML`
- `waterGoalML`
- `waterNotificationsEnabled`

The user can add or subtract 250 ml. Intake is capped at the selected goal and cannot go below zero.

The default goal is 3 L. Settings allows 2 L, 2.5 L, 3 L, 3.5 L, or 4 L.

`WaterReminderScheduler` schedules repeating notifications at 9 AM, 11 AM, 1 PM, 3 PM, and 5 PM. Notifications are requested only when needed and can be disabled from Water or Settings.

Hydration is not stored as dated history. Reports therefore use the current intake value rather than a historical daily/monthly total.

## Reports and CSV Exports

CSV document types are implemented in `App/AppViews.swift`:

### Nutrition CSV

Columns:

- Date
- Meal
- Calories (kcal)
- Protein (g)
- Carbs (g)
- Fat (g)

All saved food entries are sorted by date ascending. Meal names are quoted and escaped for CSV.

### Budget CSV

Columns:

- Date
- Name
- Amount
- Source

### Loans CSV

Columns:

- Name
- Amount Taken
- Interest Rate (%)
- Amount Paid
- Remaining Balance
- Monthly Due

`ProfileView` exposes SwiftUI file exporters for all three CSV documents.

## Email Report

`SettingsView` in `App/AppViews.swift` prepares a report addressed to the profile email using `MFMailComposeViewController`.

The report includes:

- Current-month spending and average weekly spending.
- Current-month nutrition totals.
- Current-month pedometer steps.
- Loan totals in the generated prompt.
- Current recorded water value.
- Three CSV attachments: nutrition, budget, and loans.

Gemini creates the prose summary when an API key is available. A local plain-text summary is used when Gemini is unavailable.

Email preparation requires Apple Mail to be configured on the device. The app reports that condition without affecting other features.

## Theme and Visual System

The app defines shared colors in `Views.swift`:

- `primaryOrange` for primary actions and nutrition accents.
- `accentBlue` for secondary actions and activity/finance accents.
- System background variants for light/dark compatibility.

`AppTheme` supports system, light, and dark modes through `AppStorage("appTheme")`.

The UI uses SwiftUI materials, gradients, rounded rectangles, cards, progress bars, progress rings, SF Symbols, and responsive `GeometryReader` sizing in several screens.

## Permissions and Entitlements

The app may require:

- Motion access for daily and workout steps.
- Always location access for workout routes and locked-screen distance tracking.
- Photo library access through PhotosUI for meal and receipt images.
- Notification access for hydration reminders.
- Apple Mail configuration for report sending.

The current target/project configuration should be checked in Xcode before release. The project file currently contains both project-level generated Info.plist settings and target-level settings referencing `Info.plist`; the source tree listing does not show a checked-in `Info.plist`. Verify the built app's final Info.plist contains all required usage descriptions and `UIBackgroundModes`.

## File Map

- `App/MassistApp.swift`: App entry point, theme, environment injection.
- `Core/Models.swift`: Codable domain models.
- `Core/Storage.swift`: Observable app store and persistence coordination.
- `Core/DataService.swift`: Core Data CRUD and Gemini networking.
- `Core/CoreDataStack.swift`: Programmatic Core Data model and persistent container.
- `Core/ManagedObjects.swift`: NSManagedObject classes and model conversion.
- `Core/MacroTargets.swift`: BMR, calorie/macro targets, and local image estimate.
- `App/AppViews.swift`: SwiftUI screens, navigation, nutrition, finance, settings, exports, and email reporting.
- `Features/Workout/WorkoutType.swift`: Workout modes and icons.
- `Features/Workout/WorkoutTracker.swift`: CLLocationManager, CMPedometer, timing, route, distance, pace, and workout calories.
- `Features/Workout/WorkoutView.swift`: Workout controls, statistics, map, and completion summary.
- `Features/Workout/WorkoutMapView.swift`: MapKit map and route polyline.
- `Features/Workout/WorkoutHistoryStore.swift`: CSV-backed workout records, route coordinates, and saved map snapshots.
- `Features/Workout/WorkoutHistoryView.swift`: Saved workout cards, map screenshots, and weekly steps chart with previous-week navigation.
- `Shared/ImagePicker.swift`: PhotosUI image selection wrapper.
- `Resources/prompt.txt`: Prompt template for the nutrition assistant/report guidance.
- `Resources/Assets.xcassets`: App icon and accent color assets.

## Build and Run

Open `Massist/Massist.xcodeproj` in Xcode, select the `Massist` scheme, and run on an iOS Simulator or physical iPhone.

Command-line build from the repository's inner `Massist` directory:

```sh
xcodebuild -project Massist.xcodeproj \
  -scheme Massist \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Current project settings use iOS deployment target 26.5 and Swift 5.0. The target uses automatic signing with development team `7DRQY4J5S4` and bundle identifier `com.munnaf.Massist`.

## Known Limitations and Risks

- Workout calorie calculation uses a hard-coded 70 kg rather than the profile weight.
- Workout route and distance are not persisted after the workout summary is dismissed.
- Saved workouts are persisted in `Documents/massist-workouts.csv`; route screenshots are stored as PNG files beside that CSV.
- The Home weekly steps chart aggregates saved workout records from the CSV-backed history store and does not represent steps taken outside saved workouts.
- Workout step tracking starts at workout start and does not query a historical workout interval.
- Daily home steps use a one-time query on task appearance and may not refresh continuously while the Home screen remains visible.
- Description-based AI meals are labeled as `.photo` because `EntrySource` has no description/AI case.
- The local image analysis is only a deterministic estimate, not machine learning.
- Water intake has no dated history, so monthly reports cannot reconstruct actual daily hydration.
- Loan and budget persistence uses UserDefaults rather than Core Data and has no migration/versioning layer.
- Logout does not erase locally stored data.
- Profile saving deletes and recreates the single Core Data profile object.
- Gender is collected but not used in BMR calculation.
- Gemini API keys are stored in the local profile and embedded in request URLs as query parameters.
- Gemini outputs are estimates and are not medical, nutritional, financial, or accounting advice.
- Direct mail sending depends on Apple Mail configuration.
- The target-level Info.plist configuration should be verified because the project file references an `Info.plist` while no source file is currently visible in the project directory listing.

## Guidance for Future AI Changes

1. Read the current `Views.swift` and `WorkoutTracker.swift` before editing because these files have recently received UI and location-tracking changes.
2. Preserve the single shared `AppStore` flow for profile, food, loan, and budget updates.
3. Use `DataService` for food/profile persistence; do not write directly to Core Data from views.
4. Keep all new user-entered food values tied to `FoodEntry` so totals, timeline, exports, and reports remain consistent.
5. When changing workout background behavior, update both runtime `CLLocationManager` configuration and Xcode target Info.plist/background mode configuration.
6. Validate with the project build after edits:
   `xcodebuild -project Massist.xcodeproj -scheme Massist -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
7. Test permission-dependent behavior on a physical iPhone because simulator behavior does not fully represent locked-screen location, motion, notifications, PhotosUI, or Apple Mail.
8. Avoid assuming the README is always current; confirm behavior against the source, especially for recently added manual meal entry and Diet mode selection.
