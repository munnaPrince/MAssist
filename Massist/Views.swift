//
//  Views.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

// MARK: - Theme
extension Color {
    static let primaryOrange = Color(red: 1.0, green: 0.58, blue: 0.38)
    static let accentBlue = Color(red: 0.96, green: 0.38, blue: 0.24)
    static let appBackground = Color(uiColor: .systemBackground)
    static let appSecondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let appCardBackground = Color(uiColor: .secondarySystemBackground)
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "Same as mobile theme"
        case .light: return "Light theme"
        case .dark: return "Dark theme"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if !store.loggedIn {
                LoginView()
            } else if store.profile?.age == nil || store.profile?.weightKg == nil || store.profile?.heightCm == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: store.loggedIn)
    }
}

struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var email = ""
    @State private var gender = ""

    private let genders = ["Female", "Male", "Non-binary", "Prefer not to say"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primaryOrange)
                            Text("Welcome to Btracker")
                                .font(.system(size: min(34, max(28, geometry.size.width * 0.085)), weight: .bold, design: .rounded))
                            Text("Create your profile and make every meal count.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Let’s get to know you")
                                .font(.headline)
                            RegistrationInputField(title: "Name", placeholder: "What should we call you?", icon: "person.fill", text: $name)
                            RegistrationInputField(title: "Email", placeholder: "you@example.com", icon: "envelope.fill", text: $email, isEmail: true)
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.primaryOrange)
                                    .frame(width: 28, height: 28)
                                    .background(Color.primaryOrange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("GENDER")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.secondary)

                                    Picker("Gender", selection: $gender) {
                                        Text("How do you identify?").tag("")
                                        ForEach(genders, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .tint(gender.isEmpty ? .secondary : .primary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 62)
                            .background(Color.appCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primaryOrange.opacity(gender.isEmpty ? 0.12 : 0.55), lineWidth: 1.5))

                            Button(action: {
                                let profile = UserProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: email.trimmingCharacters(in: .whitespacesAndNewlines), gender: gender)
                                store.saveProfile(profile)
                            }) {
                                Label("Create profile", systemImage: "arrow.right.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primaryOrange)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || gender.isEmpty)
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.primaryOrange.opacity(0.12), radius: 18, y: 8)

                        Text("Your information stays on this device.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct RegistrationInputField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isEmail = false
    var isEditable = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryOrange)
                .frame(width: 28, height: 28)
                .background(Color.primaryOrange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .textInputAutocapitalization(isEmail ? .never : .words)
                    .textFieldStyle(.plain)
                    .disabled(!isEditable)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primaryOrange.opacity(text.isEmpty ? 0.12 : 0.55), lineWidth: 1.5))
    }
}

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var age = 30
    @State private var weight = 70
    @State private var height = 170
    @State private var goal: GoalType = .maintain

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("STEP 1 OF 1", systemImage: "sparkles").font(.caption.weight(.bold)).foregroundColor(.accentBlue)
                                Spacer()
                                Text("Almost there").font(.caption).foregroundColor(.secondary)
                            }
                            Text("Build your baseline")
                                .font(.system(size: min(46, max(30, geometry.size.width * 0.105)), weight: .bold, design: .rounded))
                                .lineLimit(2)
                            Text("A few details help us shape your daily targets around you.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your measurements").font(.title2.weight(.bold))
                            OnboardingPickerField(title: "Age", unit: "years", icon: "calendar", range: 13...100, value: $age)
                            OnboardingPickerField(title: "Weight", unit: "kg", icon: "scalemass.fill", range: 30...250, value: $weight)
                            OnboardingPickerField(title: "Height", unit: "cm", icon: "ruler.fill", range: 100...230, value: $height)
                        }
                        .padding(18)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        VStack(alignment: .leading, spacing: 14) {
                            Label("What is your focus?", systemImage: "target").font(.headline)
                            Picker("Goal", selection: $goal) {
                                Text("Maintain").tag(GoalType.maintain)
                                Text("Muscle gain").tag(GoalType.muscleGain)
                                Text("Weight loss").tag(GoalType.weightLoss)
                            }
                            .pickerStyle(.segmented)
                            Text(goalDescription).font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center)
                        }
                        Button(action: {
                            guard var profile = store.profile else { return }
                            profile.age = age
                            profile.weightKg = Double(weight)
                            profile.heightCm = Double(height)
                            profile.goal = goal
                            store.saveProfile(profile)
                        }) {
                            Label("Continue to Btracker", systemImage: "arrow.right.circle.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentBlue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var goalDescription: String {
        switch goal {
        case .maintain: return "Keep your current routine balanced."
        case .muscleGain: return "Prioritize fuel for strength and growth."
        case .weightLoss: return "Create a steady, mindful calorie target."
        }
    }
}

struct OnboardingMetricField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    let isDecimal: Bool

    var isEditable = true

    init(title: String, value: Binding<String>, unit: String, icon: String, isDecimal: Bool, isEditable: Bool = true) {
        self.title = title
        self._value = value
        self.unit = unit
        self.icon = icon
        self.isDecimal = isDecimal
        self.isEditable = isEditable
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentBlue)
                .frame(width: 28, height: 28)
                .background(Color.accentBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: 120, alignment: .leading)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: $value)
                    .keyboardType(isDecimal ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.headline)
                    .frame(minWidth: 56, maxWidth: 90)

                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentBlue.opacity(value.isEmpty ? 0.12 : 0.55), lineWidth: 1.5))
        .opacity(isEditable ? 1 : 0.72)
        .disabled(!isEditable)
    }
}

struct OnboardingPickerField: View {
    let title: String
    let unit: String
    let icon: String
    let range: ClosedRange<Int>
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .frame(width: 28, height: 28)
                .background(Color.accentBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Picker(title, selection: $value) {
                        ForEach(Array(range), id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(unit)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary.opacity(0.75))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.accentBlue.opacity(0.35), lineWidth: 1.5))
    }
}

struct MainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            CaloriesView().tabItem { Label("Calories", systemImage: "fork.knife") }.tag(1)
            WaterView().tabItem { Label("Water", systemImage: "drop.fill") }.tag(2)
            WorkoutView().tabItem { Label("Running", systemImage: "figure.run") }.tag(3)
            ProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(4)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(5)
        }
        .tint(.primaryOrange)
    }
}

struct CaloriesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScanView(selectedTab: .constant(1))
                    .frame(maxHeight: 760)

                Divider()

                TrackerView()
                    .frame(maxHeight: 860)
            }
            .padding(.vertical, 8)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var motivation = ""
    @State private var motivationStatus = "Loading your daily motivation..."

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = store.profile {
                        let targets = MacroCalculator.targets(for: profile)
                        let consumed = consumedToday(store: store)
                        let firstName = profile.name.split(separator: " ").first.map(String.init) ?? "there"
                        let isCompact = geometry.size.width < 390

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greeting).font(.subheadline.weight(.medium)).foregroundColor(.secondary)
                                    HStack(spacing: 8) {
                                        Text(firstName).font(.system(size: 34, weight: .bold, design: .rounded))
                                        HStack(spacing: 3) {
                                            Image(systemName: "flame.fill")
                                            Text("\(NutritionStreakCalculator.currentStreak(entries: store.entries, targets: targets))")
                                        }
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.orange)
                                    }
                                }
                                Spacer()
                                Image(systemName: "leaf.circle.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(.primaryOrange)
                                    .frame(width: 56, height: 56)
                                    .background(Color.primaryOrange.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            Text(goalLabel(for: profile.goal)).font(.caption.weight(.semibold)).foregroundColor(.primaryOrange).padding(.horizontal, 10).padding(.vertical, 6).background(Color.primaryOrange.opacity(0.12)).clipShape(Capsule())
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "quote.opening").font(.title3).foregroundColor(.primaryOrange)
                            if motivation.isEmpty {
                                ProgressView()
                                Text(motivationStatus).font(.subheadline.weight(.medium)).foregroundColor(.secondary)
                            } else {
                                Text(motivation).font(.subheadline.weight(.medium))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.primaryOrange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TODAY'S FUEL").font(.caption2.weight(.bold)).foregroundColor(.white.opacity(0.75))
                                    Text("Keep your momentum going").font(.headline).foregroundColor(.white)
                                }
                                Spacer()
                                Image(systemName: "flame.fill").font(.title2).foregroundColor(.white)
                            }
                            if isCompact {
                                VStack(alignment: .center, spacing: 14) {
                                    RingView(progress: progressFraction(store: store, targetCalories: targets.calories), label: "\(consumed)", sublabel: "kcal eaten")
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)

                                    VStack(alignment: .leading, spacing: 12) {
                                        HomeStat(label: "Remaining", value: "\(max(0, targets.calories - consumed)) kcal")
                                        HomeStat(label: "Daily target", value: "\(targets.calories) kcal")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                HStack(alignment: .center, spacing: 20) {
                                    RingView(progress: progressFraction(store: store, targetCalories: targets.calories), label: "\(consumed)", sublabel: "kcal eaten")
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)

                                    VStack(alignment: .leading, spacing: 12) {
                                        HomeStat(label: "Remaining", value: "\(max(0, targets.calories - consumed)) kcal")
                                        HomeStat(label: "Daily target", value: "\(targets.calories) kcal")
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(LinearGradient(colors: [Color.primaryOrange, Color(red: 0.96, green: 0.35, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.primaryOrange.opacity(0.25), radius: 14, y: 8)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { Text("Your daily targets").font(.headline); Spacer(); Image(systemName: "chart.bar.xaxis").foregroundColor(.accentBlue) }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                HomeMacroTile(title: "Protein", value: "\(targets.proteinGrams) g", icon: "bolt.fill", color: .accentBlue)
                                HomeMacroTile(title: "Carbs", value: "\(targets.carbsGrams) g", icon: "leaf.fill", color: .green)
                                HomeMacroTile(title: "Fats", value: "\(targets.fatsGrams) g", icon: "drop.fill", color: .purple)
                                HomeMacroTile(title: "Logged", value: "\(store.entries.count) items", icon: "checkmark.circle.fill", color: .primaryOrange)
                            }
                        }
                        if store.entries.isEmpty {
                            HStack(spacing: 14) {
                                Image(systemName: "fork.knife.circle.fill").font(.title2).foregroundColor(.accentBlue)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Ready for your first entry?").font(.subheadline.weight(.semibold))
                                    Text("Scan a meal to start tracking today.").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16).background(Color.accentBlue.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task(id: store.profile?.geminiAPIKey) {
            await loadDailyMotivation()
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func goalLabel(for goal: GoalType?) -> String {
        switch goal {
        case .muscleGain: return "Muscle gain focus"
        case .weightLoss: return "Weight loss focus"
        default: return "Balanced routine"
        }
    }

    private func loadDailyMotivation() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let cachedDateKey = "dailyMotivation.date"
        let cachedQuoteKey = "dailyMotivation.quote"

        if UserDefaults.standard.string(forKey: cachedDateKey) == today,
           let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
           !cachedQuote.isEmpty {
            motivation = cachedQuote
            motivationStatus = ""
            return
        }

        guard let apiKey = store.profile?.geminiAPIKey else {
            motivationStatus = "Add your Gemini API key in Profile to receive today's motivation."
            return
        }

        do {
            let quote = try await GeminiNutritionService().motivationalQuote(apiKey: apiKey)
            UserDefaults.standard.set(today, forKey: cachedDateKey)
            UserDefaults.standard.set(quote, forKey: cachedQuoteKey)
            motivation = quote
            motivationStatus = ""
        } catch {
            motivationStatus = error.localizedDescription
        }
    }

    private func consumedToday(store: AppStore) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return store.entries.filter { Calendar.current.startOfDay(for: $0.date) == today }.reduce(0) { $0 + $1.calories }
    }

    private func progressFraction(store: AppStore, targetCalories: Int) -> Double {
        guard targetCalories > 0 else { return 0 }
        return min(1.0, Double(consumedToday(store: store)) / Double(targetCalories))
    }
}

struct HomeStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.75))
            Text(value).font(.subheadline.weight(.bold)).foregroundColor(.white)
        }
    }
}

struct HomeMacroTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).frame(width: 30, height: 30).background(color.opacity(0.12)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption).foregroundColor(.secondary); Text(value).font(.subheadline.weight(.bold)) }
            Spacer(minLength: 0)
        }
        .padding(12).background(Color.appCardBackground).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct NutritionStreakCalculator {
    static func currentStreak(entries: [FoodEntry], targets: MacroTargets) -> Int {
        let calendar = Calendar.current
        let completedDays = completedDays(entries: entries, targets: targets, calendar: calendar)
        var day = calendar.startOfDay(for: Date())

        if !completedDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), completedDays.contains(yesterday) else {
                return 0
            }
            day = yesterday
        }

        var streak = 0
        while completedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    private static func completedDays(entries: [FoodEntry], targets: MacroTargets, calendar: Calendar) -> Set<Date> {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return Set(grouped.compactMap { day, dayEntries in
            let calories = dayEntries.reduce(0) { $0 + $1.calories }
            let protein = dayEntries.reduce(0) { $0 + $1.proteinGrams }
            let carbs = dayEntries.reduce(0) { $0 + $1.carbsGrams }
            let fats = dayEntries.reduce(0) { $0 + $1.fatsGrams }
            return calories >= targets.calories && protein >= targets.proteinGrams && carbs >= targets.carbsGrams && fats >= targets.fatsGrams ? day : nil
        })
    }
}

struct RingView: View {
    var progress: Double
    var label: String
    var sublabel: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().stroke(Color.primary.opacity(0.12), lineWidth: max(10, min(18, geometry.size.width * 0.12)))
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.primaryOrange, style: StrokeStyle(lineWidth: max(10, min(18, geometry.size.width * 0.12)), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                VStack(spacing: 2) {
                    Text(label)
                        .font(.system(size: min(28, max(18, geometry.size.width * 0.24))).bold())
                    Text(sublabel)
                        .font(.system(size: min(12, max(10, geometry.size.width * 0.09))))
                        .foregroundColor(.secondary)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ScanView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedTab: Int
    @State private var showingPicker = false
    @State private var pickedImage: UIImage?
    @State private var analysis: (calories:Int, carbs:Int, protein:Int, fats:Int)? = nil
    @State private var name = "Scanned Food"
    @State private var isAnalyzing = false
    @State private var scanMessage = ""
    @State private var manualMealText = ""

    private var hasGeminiKey: Bool {
        guard let key = store.profile?.geminiAPIKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scan your meal").font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Turn a photo into a simple nutrition snapshot.").font(.subheadline).foregroundColor(.secondary)
                    }
                    VStack(spacing: 16) {
                        if let img = pickedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "viewfinder.circle.fill")
                                    .font(.system(size: 58))
                                    .foregroundColor(.primaryOrange)
                                Text("What’s on your plate?").font(.headline)
                                Text("Choose a clear photo for a quick estimate.").font(.caption).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.primaryOrange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        Button(action: { showingPicker = true }) {
                            Label(pickedImage == nil ? "Choose food photo" : "Replace photo", systemImage: "camera.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primaryOrange)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or add a meal by description")
                                .font(.subheadline.weight(.semibold))
                            TextField(
                                "e.g. 2 eggs, toast, fruit, yogurt",
                                text: $manualMealText,
                                axis: .vertical
                            )
                            .lineLimit(1...5)
                            .frame(minHeight: 80)
                            .textFieldStyle(.roundedBorder)
                            .disabled(!hasGeminiKey || isAnalyzing)
                            .submitLabel(.done)
                            .onSubmit {
                                guard hasGeminiKey else { return }
                                Task { await analyzeManualMeal() }
                            }

                            Button(action: {
                                Task { await analyzeManualMeal() }
                            }) {
                                Label("Analyze meal text", systemImage: "text.badge.checkmark")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentBlue)
                            .disabled(!hasGeminiKey || isAnalyzing || manualMealText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            if !hasGeminiKey {
                                Text("Add a Gemini API key in Profile to enable manual meal entry.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if isAnalyzing {
                            ProgressView("Analyzing with Gemini...")
                                .frame(maxWidth: .infinity)
                        }
                        if !scanMessage.isEmpty {
                            Text(scanMessage)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    if let a = analysis {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Nutrition estimate", systemImage: "sparkles").font(.headline)
                                Spacer()
                                Text(isAnalyzing ? "ANALYZING" : "READY")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(isAnalyzing ? .orange : .green)
                            }
                            RegistrationInputField(title: "Meal name", placeholder: "Name this meal", icon: "fork.knife", text: $name)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ScanNutritionTile(title: "Calories", value: "\(a.calories)", unit: "kcal", color: .primaryOrange)
                                ScanNutritionTile(title: "Protein", value: "\(a.protein)", unit: "g", color: .accentBlue)
                                ScanNutritionTile(title: "Carbs", value: "\(a.carbs)", unit: "g", color: .green)
                                ScanNutritionTile(title: "Fats", value: "\(a.fats)", unit: "g", color: .purple)
                            }
                            Button(action: {
                                let entry = FoodEntry(name: name, calories: a.calories, carbsGrams: a.carbs, proteinGrams: a.protein, fatsGrams: a.fats, source: .manual)
                                store.addEntry(entry)
                                pickedImage = nil
                                analysis = nil
                                manualMealText = ""
                                selectedTab = 2
                            }) {
                                Label("Add to today", systemImage: "plus.circle.fill")
                                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentBlue)
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(image: $pickedImage)
                .onChange(of: pickedImage) { _, new in
                    if let img = new {
                        Task { await analyzeImage(img) }
                    }
                }
        }
    }

    private func analyzeImage(_ image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            scanMessage = ""
            analysis = nil
        }
        do {
            guard let profile = store.profile else { throw GeminiNutritionError.invalidAPIKey }
            let result = try await GeminiNutritionService().analyze(image: image, apiKey: profile.geminiAPIKey ?? "")
            await MainActor.run {
                name = result.name
                analysis = (result.calories, result.carbs, result.protein, result.fats)
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                analysis = MacroCalculator.analyzeImage(image)
                isAnalyzing = false
                scanMessage = "AI unavailable: \(error.localizedDescription) Showing a local estimate."
            }
        }
    }

    private func analyzeManualMeal() async {
        let input = manualMealText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        guard let profile = store.profile else {
            await MainActor.run {
                scanMessage = "Please create or restore your profile before analyzing meals."
            }
            return
        }

        guard let apiKey = profile.geminiAPIKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                scanMessage = "Add a Gemini API key in Profile to enable manual meal entry."
            }
            return
        }

        await MainActor.run {
            isAnalyzing = true
            scanMessage = ""
            analysis = nil
        }

        do {
            let result = try await GeminiNutritionService().analyzeText(description: input, apiKey: apiKey)
            await MainActor.run {
                name = result.name
                analysis = (result.calories, result.carbs, result.protein, result.fats)
                isAnalyzing = false
                manualMealText = ""
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                scanMessage = "AI unavailable: \(error.localizedDescription)"
            }
        }
    }
}

struct ScanNutritionTile: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.title3.weight(.bold)).foregroundColor(color)
                Text(unit).font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TrackerView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        let totals = dailyTotals(entries: store.entries)
        let todayEntries = entriesForToday(store.entries)
        let targets = store.profile.map { MacroCalculator.targets(for: $0) }

        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Nutrition tracker")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(Date(), style: .date)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TODAY'S PROGRESS")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white.opacity(0.75))
                                Text("\(totals.calories) kcal")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        if let targets {
                            TrackerProgressBar(value: totals.calories, target: targets.calories, color: .white)
                            Text("\(max(0, targets.calories - totals.calories)) kcal remaining of \(targets.calories) kcal")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                Text("\(NutritionStreakCalculator.currentStreak(entries: store.entries, targets: targets)) day nutrition streak")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        } else {
                            Text("Start logging meals to see your progress.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(LinearGradient(colors: [.primaryOrange, Color(red: 0.94, green: 0.30, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.primaryOrange.opacity(0.25), radius: 14, y: 8)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Macro balance").font(.headline)
                            Spacer()
                            Text("TODAY").font(.caption2.weight(.bold)).foregroundColor(.secondary)
                        }
                        if let targets {
                            TrackerMacroRow(title: "Protein", value: totals.protein, target: targets.proteinGrams, color: .accentBlue)
                            TrackerMacroRow(title: "Carbs", value: totals.carbs, target: targets.carbsGrams, color: .green)
                            TrackerMacroRow(title: "Fat", value: totals.fats, target: targets.fatsGrams, color: .purple)
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    HStack {
                        Label("Meal timeline", systemImage: "clock.fill").font(.headline)
                        Spacer()
                        Text("\(todayEntries.count) logged").font(.caption).foregroundColor(.secondary)
                    }

                    if todayEntries.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 42))
                                .foregroundColor(.primaryOrange)
                            Text("Your day starts here").font(.headline)
                            Text("Scan a meal to build your nutrition timeline.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(Color.primaryOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        VStack(spacing: 0) {
                            ForEach(todayEntries) { entry in
                                TrackerMealRow(entry: entry)
                                if entry.id != todayEntries.last?.id {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(20)
            }
        }
    }

    private func entriesForToday(_ entries: [FoodEntry]) -> [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.filter { Calendar.current.startOfDay(for: $0.date) == today }.sorted { $0.date > $1.date }
    }

    func dailyTotals(entries: [FoodEntry]) -> (calories:Int, protein:Int, carbs:Int, fats:Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let s = entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
        return (s.reduce(0) { $0 + $1.calories }, s.reduce(0) { $0 + $1.proteinGrams }, s.reduce(0) { $0 + $1.carbsGrams }, s.reduce(0) { $0 + $1.fatsGrams })
    }
}

struct TrackerProgressBar: View {
    let value: Int
    let target: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.25))
                Capsule().fill(color).frame(width: geometry.size.width * min(1, CGFloat(value) / CGFloat(max(target, 1))))
            }
        }
        .frame(height: 8)
    }
}

struct TrackerMacroRow: View {
    let title: String
    let value: Int
    let target: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value) / \(target) g").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            TrackerProgressBar(value: value, target: target, color: color)
        }
    }
}

struct TrackerMealRow: View {
    @EnvironmentObject var store: AppStore
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .foregroundColor(.primaryOrange)
                .frame(width: 36, height: 36)
                .background(Color.primaryOrange.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name).font(.subheadline.weight(.semibold))
                Text(entry.date, style: .time).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(entry.calories) kcal").font(.subheadline.weight(.bold))
                Text("P \(entry.proteinGrams) • C \(entry.carbsGrams) • F \(entry.fatsGrams)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(entry.source == .manual ? "Typed meal" : "Photo scan")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(entry.source == .manual ? .accentBlue : .primaryOrange)
            }
        }
        .padding(.vertical, 14)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct WaterView: View {
    @AppStorage("waterIntakeML") private var waterIntakeML = 0
    @AppStorage("waterGoalML") private var waterGoalML = 3000
    @AppStorage("waterNotificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        let goalML = max(waterGoalML, 3000)
        let progress = min(1, Double(waterIntakeML) / Double(goalML))
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hydration check-in").font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Stay refreshed through your workday.").font(.subheadline).foregroundColor(.secondary)
                    }
                    VStack(spacing: 14) {
                        HStack {
                            Image(systemName: "drop.fill").font(.title).foregroundColor(.white)
                            Spacer()
                            Text("TODAY").font(.caption2.weight(.bold)).foregroundColor(.white.opacity(0.75))
                        }
                        Text("\(Double(waterIntakeML) / 1000.0, specifier: "%.1f") L").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("of \(Double(goalML) / 1000.0, specifier: "%.1f") L goal").font(.subheadline).foregroundColor(.white.opacity(0.8))
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.25))
                                Capsule().fill(Color.white).frame(width: geometry.size.width * progress)
                            }
                        }.frame(height: 10)
                    }
                    .padding(22)
                    .background(LinearGradient(colors: [.primaryOrange, Color(red: 0.94, green: 0.30, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    HStack(spacing: 12) {
                        WaterAddButton(amount: 250, action: { addWater(250) })
                        WaterMinusButton(amount: 250, action: { minusWater(250) })
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Workday reminders", systemImage: "bell.fill").font(.headline)
                            Spacer()
                            Toggle("Reminders", isOn: $notificationsEnabled)
                                .labelsHidden().tint(.primaryOrange)
                                .onChange(of: notificationsEnabled) { _, enabled in
                                    Task { await WaterReminderScheduler.update(enabled: enabled) }
                                }
                        }
                        Text(notificationsEnabled ? "Gentle reminders are scheduled from 9 AM to 5 PM." : "Reminders are currently paused.")
                            .font(.caption).foregroundColor(.secondary)
                        Text("A 3 L goal is a practical default for a desk-based workday, but your ideal amount varies with body size, activity, climate, and medical needs.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
                    Button("Reset today") { waterIntakeML = 0 }
                        .font(.subheadline.weight(.semibold)).foregroundColor(.red).frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .task { if notificationsEnabled { await WaterReminderScheduler.update(enabled: true) } }
    }

    private func addWater(_ amount: Int) {
        waterIntakeML = min(waterGoalML, waterIntakeML + amount)
    }

    private func minusWater(_ amount: Int) {
        waterIntakeML = max(0, waterIntakeML - amount)
    }

}

struct WaterAddButton: View {
    let amount: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("+\(amount) ml", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent).tint(.primaryOrange)
    }
}

struct WaterMinusButton: View {
    let amount: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("-\(amount) ml", systemImage: "minus.circle.fill")
                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent).tint(.primaryOrange)
    }
}

enum WaterReminderScheduler {
    static func update(enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: reminderIDs)
        guard enabled else { return }
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let refreshed = await center.notificationSettings()
        guard refreshed.authorizationStatus == .authorized else { return }
        for hour in [9, 11, 13, 15, 17] {
            let content = UNMutableNotificationContent()
            content.title = "Hydration break"
            content.body = "Take a moment to drink some water."
            content.sound = .default
            var components = DateComponents()
            components.hour = hour
            let request = UNNotificationRequest(identifier: "water-reminder-\(hour)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
            try? await center.add(request)
        }
    }

    private static let reminderIDs = ["water-reminder-9", "water-reminder-11", "water-reminder-13", "water-reminder-15", "water-reminder-17"]
}

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var name = ""
    @State private var email = ""
    @State private var gender = ""
    @State private var age = 30
    @State private var weight = 70
    @State private var height = 170
    @State private var calorieTarget = ""
    @State private var proteinTarget = ""
    @State private var fatTarget = ""
    @State private var customTargets = false
    @State private var savedMessage = false
    @State private var isEditing = false
    @State private var targetWarning = ""
    @State private var isExportingNutrition = false
    @State private var nutritionExportDocument = NutritionCSVDocument()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let p = store.profile {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Your profile")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.secondary)
                                        Text(name.isEmpty ? "Your details" : name)
                                            .font(.system(size: min(32, max(24, geometry.size.width * 0.08)), weight: .bold, design: .rounded))
                                    }
                                    Spacer()
                                    Circle()
                                        .fill(LinearGradient(colors: [.primaryOrange, Color(red: 0.94, green: 0.30, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 62, height: 62)
                                        .overlay(Text(String((name.isEmpty ? p.email : name).prefix(1)).uppercased()).font(.title2.weight(.bold)).foregroundColor(.white))
                                }
                                Text("Keep your information and nutrition plan up to date.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .onAppear { loadProfile(p) }

                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label("Personal details", systemImage: "person.text.rectangle.fill")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            isEditing.toggle()
                                            savedMessage = false
                                            targetWarning = ""
                                        }
                                    }) {
                                        Image(systemName: isEditing ? "xmark" : "pencil")
                                            .font(.headline.weight(.semibold))
                                            .foregroundColor(.accentBlue)
                                            .frame(width: 40, height: 40)
                                            .background(Color.accentBlue.opacity(0.12))
                                            .clipShape(Circle())
                                    }
                                    .accessibilityLabel(isEditing ? "Cancel editing" : "Edit profile")
                                }
                                RegistrationInputField(title: "Name", placeholder: "Your name", icon: "person.fill", text: $name, isEditable: isEditing)
                                RegistrationInputField(title: "Email", placeholder: "Email address", icon: "envelope.fill", text: $email, isEmail: true, isEditable: isEditing)
                                ProfileGenderField(gender: $gender, isEditable: isEditing)
                                ProfilePickerField(title: "Age", unit: "years", icon: "calendar", value: $age, range: 13...100, isEditable: isEditing)
                                ProfilePickerField(title: "Weight", unit: "kg", icon: "scalemass.fill", value: $weight, range: 30...250, isEditable: isEditing)
                                ProfilePickerField(title: "Height", unit: "cm", icon: "ruler.fill", value: $height, range: 100...230, isEditable: isEditing)
                            }
                            .padding(20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label("Nutrition targets", systemImage: "chart.bar.fill")
                                        .font(.headline)
                                    Spacer()
                                    Toggle("Custom", isOn: $customTargets)
                                        .labelsHidden()
                                        .tint(.accentBlue)
                                        .disabled(!isEditing)
                                }
                                Text(customTargets ? "Set targets that work best for your plan." : "Targets are calculated from your profile and goal.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if customTargets {
                                    OnboardingMetricField(title: "Calories", value: $calorieTarget, unit: "kcal", icon: "flame.fill", isDecimal: false, isEditable: isEditing)
                                    OnboardingMetricField(title: "Protein", value: $proteinTarget, unit: "g", icon: "bolt.fill", isDecimal: false, isEditable: isEditing)
                                    OnboardingMetricField(title: "Fat", value: $fatTarget, unit: "g", icon: "drop.fill", isDecimal: false, isEditable: isEditing)
                                    if !targetWarning.isEmpty {
                                        Label(targetWarning, systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.orange)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.orange.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                } else {
                                    let targets = MacroCalculator.targets(for: p)
                                    HStack(spacing: 10) {
                                        ProfileTargetBadge(value: "\(targets.calories)", label: "kcal", color: .primaryOrange)
                                        ProfileTargetBadge(value: "\(targets.proteinGrams)g", label: "protein", color: .accentBlue)
                                        ProfileTargetBadge(value: "\(targets.fatsGrams)g", label: "fat", color: .purple)
                                    }
                                }
                            }
                            .padding(20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            Button(action: {
                                saveProfile()
                                withAnimation { isEditing = false }
                            }) {
                                Label(savedMessage ? "Changes saved" : "Save changes", systemImage: savedMessage ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentBlue)
                            .disabled(!isEditing)
                            .opacity(isEditing ? 1 : 0.55)

                            VStack(alignment: .leading, spacing: 14) {
                                Label("Nutrition history", systemImage: "arrow.down.doc.fill")
                                    .font(.headline)
                                Text("Download every saved meal with its date and nutrition values.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    nutritionExportDocument = NutritionCSVDocument(entries: store.entries)
                                    isExportingNutrition = true
                                }) {
                                    Label("Download nutrition CSV", systemImage: "arrow.down.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primaryOrange)
                                .disabled(store.entries.isEmpty)
                                if store.entries.isEmpty {
                                    Text("Add a meal before downloading your nutrition history.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            Button("Log out") { store.logout() }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingNutrition,
            document: nutritionExportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "btracker-nutrition-history"
        ) { _ in }
    }

    private func loadProfile(_ profile: UserProfile) {
        guard name.isEmpty else { return }
        name = profile.name
        email = profile.email
        gender = profile.gender ?? ""
        age = profile.age ?? 30
        weight = Int(profile.weightKg ?? 70)
        height = Int(profile.heightCm ?? 170)
        customTargets = profile.calorieTarget != nil || profile.proteinTarget != nil || profile.fatTarget != nil
        let targets = MacroCalculator.targets(for: profile)
        calorieTarget = String(targets.calories)
        proteinTarget = String(targets.proteinGrams)
        fatTarget = String(targets.fatsGrams)
    }

    private func saveProfile() {
        guard var profile = store.profile else { return }
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.gender = gender.isEmpty ? nil : gender
        profile.age = age
        profile.weightKg = Double(weight)
        profile.heightCm = Double(height)
        if customTargets {
            var suggestedProfile = profile
            suggestedProfile.calorieTarget = nil
            suggestedProfile.proteinTarget = nil
            suggestedProfile.fatTarget = nil
            let suggested = MacroCalculator.targets(for: suggestedProfile)
            let calories = Int(calorieTarget) ?? suggested.calories
            let protein = Int(proteinTarget) ?? suggested.proteinGrams
            let fats = Int(fatTarget) ?? suggested.fatsGrams
            if calories < suggested.calories || protein < suggested.proteinGrams || fats < suggested.fatsGrams {
                targetWarning = "Your targets cannot be lower than the suggested minimums: \(suggested.calories) kcal, \(suggested.proteinGrams) g protein, and \(suggested.fatsGrams) g fat."
                return
            }
            profile.calorieTarget = calories
            profile.proteinTarget = protein
            profile.fatTarget = fats
        } else {
            profile.calorieTarget = nil
            profile.proteinTarget = nil
            profile.fatTarget = nil
        }
        store.saveProfile(profile)
        withAnimation { savedMessage = true }
    }
}

struct NutritionCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    private var contents: String

    init() {
        contents = "Date,Meal,Calories (kcal),Protein (g),Carbs (g),Fat (g)\n"
    }

    init(entries: [FoodEntry]) {
        let formatter = ISO8601DateFormatter()
        let rows = entries.sorted { $0.date < $1.date }.map { entry in
            [
                formatter.string(from: entry.date),
                Self.escape(entry.name),
                String(entry.calories),
                String(entry.proteinGrams),
                String(entry.carbsGrams),
                String(entry.fatsGrams)
            ].joined(separator: ",")
        }
        contents = (["Date,Meal,Calories (kcal),Protein (g),Carbs (g),Fat (g)"] + rows).joined(separator: "\n") + "\n"
    }

    init(configuration: ReadConfiguration) throws {
        contents = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(contents.utf8))
    }

    private static func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

struct ProfileGenderField: View {
    @Binding var gender: String
    let isEditable: Bool
    private let genders = ["Female", "Male", "Non-binary", "Prefer not to say"]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill").foregroundColor(.primaryOrange).frame(width: 24)
            Picker("Gender", selection: $gender) {
                Text("Select gender").tag("")
                ForEach(genders, id: \.self) { option in Text(option).tag(option) }
            }
            .pickerStyle(.menu)
            .tint(gender.isEmpty ? .secondary : .primary)
            .disabled(!isEditable)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primaryOrange.opacity(0.15), lineWidth: 1.5))
    }
}

struct APIKeyInputField: View {
    @Binding var value: String
    let isEditable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundColor(.accentBlue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("GEMINI API KEY")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                SecureField("Paste your Gemini key", text: $value)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!isEditable)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentBlue.opacity(isEditable ? 0.45 : 0.12), lineWidth: 1.5))
        .opacity(isEditable ? 1 : 0.72)
    }
}

struct ProfilePickerField: View {
    let title: String
    let unit: String
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let isEditable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .frame(width: 28, height: 28)
                .background(Color.accentBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Picker(title, selection: $value) {
                        ForEach(Array(range), id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 120)
                    .disabled(!isEditable)

                    Text(unit)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentBlue.opacity(isEditable ? 0.45 : 0.12), lineWidth: 1.5))
        .opacity(isEditable ? 1 : 0.72)
    }
}

struct ProfileTargetBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.headline.weight(.bold)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("waterNotificationsEnabled") private var notificationsEnabled = true
    @AppStorage("waterGoalML") private var waterGoalML = 3000
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var geminiAPIKey = ""
    @State private var saved = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Settings").font(.system(size: min(32, max(24, geometry.size.width * 0.08)), weight: .bold, design: .rounded))
                            Text("Make Btracker fit your workday.").font(.subheadline).foregroundColor(.secondary)
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Appearance", systemImage: "paintbrush.fill").font(.headline)
                            Text("Choose the theme for the app. Mobile theme follows the system setting by default.")
                                .font(.caption).foregroundColor(.secondary)
                            Picker("App theme", selection: $appTheme) {
                                ForEach(AppTheme.allCases, id: \.self) { theme in
                                    Text(theme.title).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 16) {
                            Label("AI nutrition assistant", systemImage: "sparkles").font(.headline)
                            Text("Your key stays on this device and is used for food analysis and daily motivation.")
                                .font(.caption).foregroundColor(.secondary)
                            APIKeyInputField(value: $geminiAPIKey, isEditable: true)
                            Button(action: saveSettings) {
                                Label(saved ? "Saved" : "Save API key", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent).tint(.primaryOrange)
                        }
                        .padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Hydration reminders", systemImage: "drop.fill").font(.headline)
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Workday notifications").font(.subheadline.weight(.medium))
                                    Text("9 AM, 11 AM, 1 PM, 3 PM, and 5 PM").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("Water reminders", isOn: $notificationsEnabled)
                                    .labelsHidden().tint(.primaryOrange)
                                    .onChange(of: notificationsEnabled) { _, enabled in
                                        Task { await WaterReminderScheduler.update(enabled: enabled) }
                                    }
                            }
                            HStack {
                                Text("Daily goal").font(.subheadline.weight(.medium))
                                Spacer()
                                Picker("Daily goal", selection: $waterGoalML) {
                                    Text("2 L").tag(2000)
                                    Text("2.5 L").tag(2500)
                                    Text("3 L").tag(3000)
                                    Text("3.5 L").tag(3500)
                                    Text("4 L").tag(4000)
                                }
                                .pickerStyle(.menu).tint(.primaryOrange)
                            }
                        }
                        .padding(20).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            geminiAPIKey = store.profile?.geminiAPIKey ?? ""
            if waterGoalML < 1 { waterGoalML = 3000 }
        }
    }

    private func saveSettings() {
        guard var profile = store.profile else { return }
        let key = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.geminiAPIKey = key.isEmpty ? nil : key
        store.saveProfile(profile)
        saved = true
    }
}
