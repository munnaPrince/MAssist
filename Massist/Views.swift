//
//  Views.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import SwiftUI
import CoreMotion
import MessageUI
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
                            Text("Welcome to MAssist")
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
                            Label("Continue to MAssist", systemImage: "arrow.right.circle.fill")
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
            CaloriesView().tabItem { Label("Diet", systemImage: "fork.knife") }.tag(1)
            BudgetTrackerView().tabItem { Label("Expenses", systemImage: "chart.pie.fill") }.tag(2)
            LoansTrackerView().tabItem { Label("Loans", systemImage: "banknote.fill") }.tag(3)
            WorkoutView().tabItem { Label("Activity", systemImage: "figure.run") }.tag(4)
            WaterView().tabItem { Label("Water", systemImage: "drop.fill") }.tag(5)
            ProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(6)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(7)
        }
        .tint(.primaryOrange)
    }
}

struct CaloriesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScanView()
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
    @State private var todaySteps = 0
    @AppStorage("waterIntakeML") private var waterIntakeML = 0
    @AppStorage("waterGoalML") private var waterGoalML = 3000
    private let pedometer = CMPedometer()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = store.profile {
                        let targets = MacroCalculator.targets(for: profile)
                        let todayTotals = dailyTotals(entries: store.entries)
                        let firstName = profile.name.split(separator: " ").first.map(String.init) ?? "there"
                        let remainingCalories = max(0, targets.calories - todayTotals.calories)
                        let waterLitres = Double(waterIntakeML) / 1000.0
                        let caloriesProgress = targets.calories > 0 ? min(1.0, Double(todayTotals.calories) / Double(targets.calories)) : 0
                        let proteinProgress = targets.proteinGrams > 0 ? min(1.0, Double(todayTotals.protein) / Double(targets.proteinGrams)) : 0
                        let fatsProgress = targets.fatsGrams > 0 ? min(1.0, Double(todayTotals.fats) / Double(targets.fatsGrams)) : 0
                        let waterProgress = waterGoalML > 0 ? min(1.0, Double(waterIntakeML) / Double(waterGoalML)) : 0
                        let stepsProgress = min(1.0, Double(todaySteps) / 10000.0)
                        let todaySpending = spendingToday(records: store.budgetRecords)
                        let totalAmountTaken = store.loans.reduce(0) { $0 + $1.amountTaken }
                        let totalAmountPaid = store.loans.reduce(0) { $0 + $1.amountPaid }

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

                        NavigationLink {
                            NutritionAskView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles")
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.18))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Ask")
                                        .font(.headline.weight(.bold))
                                    Text("Get nutrition guidance for your day")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.82))
                                }

                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [.accentBlue, .primaryOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Daily overview").font(.headline)
                                Spacer()
                                Image(systemName: "sparkles").foregroundColor(.primaryOrange)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                HomeMetricCard(title: "Calories", value: "\(todayTotals.calories)", unit: "kcal", subtitle: "\(remainingCalories) left", icon: "flame.fill", accent: .primaryOrange, progress: caloriesProgress)
                                HomeMetricCard(title: "Protein", value: "\(todayTotals.protein)", unit: "g", subtitle: "\(targets.proteinGrams) goal", icon: "bolt.fill", accent: .accentBlue, progress: proteinProgress)
                                HomeMetricCard(title: "Fats", value: "\(todayTotals.fats)", unit: "g", subtitle: "\(targets.fatsGrams) goal", icon: "drop.fill", accent: .purple, progress: fatsProgress)
                                HomeMetricCard(title: "Water", value: String(format: "%.1f", waterLitres), unit: "L", subtitle: "\(String(format: "%.1f", Double(waterGoalML) / 1000.0)) L goal", icon: "drop.fill", accent: .blue, progress: waterProgress)
                                HomeMetricCard(title: "Steps", value: "\(todaySteps)", unit: "steps", subtitle: "daily goal", icon: "shoeprints.fill", accent: .green, progress: stepsProgress)
                            }
                        }
                        .padding(18)
                        .background(Color.appCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Money snapshot").font(.headline)
                                Spacer()
                                Image(systemName: "wallet.pass.fill").foregroundColor(.accentBlue)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                HomeFinanceCard(title: "Today's spending", value: currency(todaySpending), subtitle: "budget records", icon: "cart.fill", accent: .primaryOrange)
                                HomeFinanceCard(title: "Amount taken", value: currency(totalAmountTaken), subtitle: "across loans", icon: "arrow.down.circle.fill", accent: .accentBlue)
                                HomeFinanceCard(title: "Amount paid", value: currency(totalAmountPaid), subtitle: "loan repayments", icon: "checkmark.circle.fill", accent: .green)
                            }
                        }
                        .padding(18)
                        .background(
                            LinearGradient(
                                colors: [Color.accentBlue.opacity(0.10), Color.appCardBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))

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
            .task {
                loadTodaySteps()
                await loadDailyMotivation()
            }
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

    private func loadTodaySteps() {
        guard CMPedometer.isStepCountingAvailable() else {
            todaySteps = 0
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { data, error in
            let steps = data.flatMap { Int(truncating: $0.numberOfSteps) } ?? 0
            DispatchQueue.main.async {
                self.todaySteps = steps
            }
        }
    }

    private func dailyTotals(entries: [FoodEntry]) -> (calories: Int, protein: Int, carbs: Int, fats: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let s = entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
        return (
            s.reduce(0) { $0 + $1.calories },
            s.reduce(0) { $0 + $1.proteinGrams },
            s.reduce(0) { $0 + $1.carbsGrams },
            s.reduce(0) { $0 + $1.fatsGrams }
        )
    }

    private func spendingToday(records: [BudgetRecord]) -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return records
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.amount }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

struct NutritionAskView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("waterIntakeML") private var waterIntakeML = 0
    @State private var question = ""
    @State private var answer = ""
    @State private var errorMessage = ""
    @State private var isAsking = false
    @FocusState private var questionFocused: Bool

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Ask your nutritionist")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.accentBlue)
                                .clipShape(Circle())
                        }
                        Text("Your answer is shaped around your profile and today's progress.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Label("What would you like to know?", systemImage: "bubble.left.and.text.bubble.right.fill")
                            .font(.headline)

                        TextField("e.g. What should I eat for more protein today?", text: $question, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($questionFocused)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(Color.appCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.accentBlue.opacity(question.isEmpty ? 0.16 : 0.55), lineWidth: 1.5)
                            )

                        Button {
                            Task { await askQuestion() }
                        } label: {
                            HStack {
                                Image(systemName: isAsking ? "hourglass" : "paperplane.fill")
                                Text(isAsking ? "Thinking..." : "Ask Gemini")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentBlue)
                        .disabled(isAsking || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.profile?.geminiAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false)

                        if store.profile?.geminiAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                            Label("Add your Gemini API key in Profile to ask a question.", systemImage: "key.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    if isAsking {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Reviewing your nutrition context...")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                    }

                    if !answer.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Your answer", systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                    .foregroundColor(.accentBlue)
                                Spacer()
                                Text("GEMINI")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.secondary)
                            }
                            Text(answer)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(Color.accentBlue.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Ask")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func askQuestion() async {
        guard let profile = store.profile,
              let apiKey = profile.geminiAPIKey,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = GeminiNutritionError.invalidAPIKey.localizedDescription
            return
        }

        let totals = dailyTotals(entries: store.entries)
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let renderedPrompt = nutritionPrompt(
            profile: profile,
            totals: totals,
            water: waterIntakeML,
            question: trimmedQuestion
        )

        await MainActor.run {
            isAsking = true
            answer = ""
            errorMessage = ""
            questionFocused = false
        }

        do {
            let response = try await GeminiNutritionService().generateReportSummary(prompt: renderedPrompt, apiKey: apiKey)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    answer = response
                }
                isAsking = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAsking = false
            }
        }
    }

    private func nutritionPrompt(
        profile: UserProfile,
        totals: (calories: Int, protein: Int, carbs: Int, fats: Int),
        water: Int,
        question: String
    ) -> String {
        let template = (Bundle.main.url(forResource: "prompt", withExtension: "txt"))
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
            ?? "You are a professional nutritionist. Give concise, practical, non-diagnostic nutrition guidance."

        return template
            .replacingOccurrences(of: "{{age}}", with: String(profile.age ?? 0))
            .replacingOccurrences(of: "{{height}}", with: String(format: "%.0f", profile.heightCm ?? 0))
            .replacingOccurrences(of: "{{weight}}", with: String(format: "%.1f", profile.weightKg ?? 0))
            .replacingOccurrences(of: "{{goal}}", with: goalLabel(for: profile.goal))
            .replacingOccurrences(of: "{{calories}}", with: String(totals.calories))
            .replacingOccurrences(of: "{{protein}}", with: String(totals.protein))
            .replacingOccurrences(of: "{{fat}}", with: String(totals.fats))
            .replacingOccurrences(of: "{{water}}", with: String(water))
            + "\n\nUser's question:\n\(question)\n\nAnswer the user's question using the context above. Keep the required response structure and stay within 120-150 words."
    }

    private func goalLabel(for goal: GoalType?) -> String {
        switch goal {
        case .muscleGain: return "Muscle Gain"
        case .weightLoss: return "Muscle Loss / Weight Loss"
        default: return "Weight Maintenance"
        }
    }

    private func dailyTotals(entries: [FoodEntry]) -> (calories: Int, protein: Int, carbs: Int, fats: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayEntries = entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
        return (
            todayEntries.reduce(0) { $0 + $1.calories },
            todayEntries.reduce(0) { $0 + $1.proteinGrams },
            todayEntries.reduce(0) { $0 + $1.carbsGrams },
            todayEntries.reduce(0) { $0 + $1.fatsGrams }
        )
    }
}

struct HomeMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let icon: String
    let accent: Color
    let progress: Double

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(accent)
                        .frame(width: 26, height: 26)
                        .background(accent.opacity(0.12))
                        .clipShape(Circle())
                    Spacer()
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value).font(.title2.weight(.bold))
                        Text(unit).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    }
                    Text(subtitle).font(.caption2).foregroundColor(.secondary)
                }
            }

            MiniProgressRing(value: progress, accent: accent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [accent.opacity(0.16), Color.appCardBackground]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: accent.opacity(0.08), radius: 10, x: 0, y: 8)
    }
}

struct HomeFinanceCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.14))
                .clipShape(Circle())

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(2)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MiniProgressRing: View {
    let value: Double
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.18), lineWidth: 5)
            Circle()
                .trim(from: 0, to: value)
                .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: value)

            Text("\(Int(round(value * 100)))%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(accent)
        }
        .frame(width: 46, height: 46)
    }
}

struct BudgetTrackerView: View {
    @EnvironmentObject var store: AppStore
    @FocusState private var focusedField: BudgetField?
    @State private var inputMode = BudgetInputMode.manual
    @State private var showingPicker = false
    @State private var pickedImage: UIImage?
    @State private var receiptAnalysis: (name: String, amount: Double)?
    @State private var recordName = ""
    @State private var recordAmount = ""
    @State private var isAnalyzing = false
    @State private var message = ""
    @State private var recordDate = Date()

    private var todayRecords: [BudgetRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.budgetRecords.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var todayTotal: Double {
        todayRecords.reduce(0) { $0 + $1.amount }
    }

    private var hasGeminiKey: Bool {
        guard let key = store.profile?.geminiAPIKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Expenses")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("See where your everyday spending goes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TODAY'S SPENDING")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white.opacity(0.75))
                                Text(currency(todayTotal))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        Text("\(todayRecords.count) record\(todayRecords.count == 1 ? "" : "s") logged today")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.82))
                    }
                    .padding(22)
                    .background(
                        LinearGradient(
                            colors: [.accentBlue, Color(red: 0.72, green: 0.12, blue: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.accentBlue.opacity(0.22), radius: 14, y: 8)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: inputMode == .manual ? "pencil.and.list.clipboard" : "doc.viewfinder.fill")
                                .font(.title3)
                                .foregroundColor(.primaryOrange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a spending record")
                                    .font(.headline)
                                Text(inputMode == .manual ? "Log a purchase in a few taps." : "Let Gemini read the bill total for you.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Picker("Record type", selection: $inputMode) {
                            ForEach(BudgetInputMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if inputMode == .manual {
                            TextField("What did you buy?", text: $recordName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                            HStack {
                                TextField("Amount", text: $recordAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .amount)
                                Text("in your currency")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            Button(action: addManualRecord) {
                                Label("Add record", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primaryOrange)
                            .disabled(recordName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(recordAmount) ?? 0) <= 0)
                        } else {
                            Button(action: { showingPicker = true }) {
                                Label(pickedImage == nil ? "Upload bill photo" : "Replace bill photo", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primaryOrange)
                            .disabled(isAnalyzing)

                            if let pickedImage {
                                Image(uiImage: pickedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 170)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            if isAnalyzing {
                                ProgressView("Reading bill with Gemini...")
                                    .frame(maxWidth: .infinity)
                            } else if let receiptAnalysis {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Receipt found")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Text(receiptAnalysis.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(currency(receiptAnalysis.amount))
                                            .font(.title3.weight(.bold))
                                            .foregroundColor(.primaryOrange)
                                    }
                                    Button(action: addReceiptRecord) {
                                        Label("Add to budget", systemImage: "checkmark.circle.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.accentBlue)
                                }
                                .padding(14)
                                .background(Color.primaryOrange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else if !hasGeminiKey {
                                Text("Add a Gemini API key in Profile to scan bills.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        DatePicker("Record date", selection: $recordDate, displayedComponents: .date)

                        if !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(18)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    HStack {
                        Label("Recent spending", systemImage: "clock.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(store.budgetRecords.count) total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if store.budgetRecords.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.primaryOrange)
                            Text("Your spending story starts here")
                                .font(.headline)
                            Text("Add a bill or purchase to see your budget take shape.")
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
                            ForEach(store.budgetRecords) { record in
                                BudgetRecordRow(record: record, onDelete: { store.deleteBudgetRecord(record) })
                                if record.id != store.budgetRecords.last?.id {
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
            .background(Color.appBackground.ignoresSafeArea())
            .sheet(isPresented: $showingPicker) {
                ImagePicker(image: $pickedImage)
                    .onChange(of: pickedImage) { _, newImage in
                        if let newImage {
                            Task { await analyzeReceipt(newImage) }
                        }
                    }
            }
        }
    }

    private func addManualRecord() {
        let cleanedName = recordName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty, let amount = Double(recordAmount), amount > 0 else { return }
        store.addBudgetRecord(BudgetRecord(date: recordDate, name: cleanedName, amount: amount, source: .manual))
        focusedField = nil
        recordName = ""
        recordAmount = ""
        recordDate = Date()
        message = ""
    }

    private func addReceiptRecord() {
        guard let receiptAnalysis else { return }
        store.addBudgetRecord(BudgetRecord(date: recordDate, name: receiptAnalysis.name, amount: receiptAnalysis.amount, source: .receipt))
        pickedImage = nil
        self.receiptAnalysis = nil
        recordDate = Date()
        message = ""
    }

    private func analyzeReceipt(_ image: UIImage) async {
        guard hasGeminiKey, let apiKey = store.profile?.geminiAPIKey else {
            await MainActor.run { message = "Add a Gemini API key in Profile to scan bills." }
            return
        }

        await MainActor.run {
            isAnalyzing = true
            receiptAnalysis = nil
            message = ""
        }
        do {
            let result = try await GeminiNutritionService().analyzeReceipt(image: image, apiKey: apiKey)
            await MainActor.run {
                receiptAnalysis = result
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                isAnalyzing = false
                message = "Could not read this bill: \(error.localizedDescription)"
            }
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

private enum BudgetInputMode: String, CaseIterable {
    case manual
    case receipt

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .receipt: return "Bill photo"
        }
    }
}

private enum BudgetField: Hashable {
    case name
    case amount
}

private struct BudgetRecordRow: View {
    let record: BudgetRecord
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.source == .receipt ? "doc.text.viewfinder" : "cart.fill")
                .foregroundColor(record.source == .receipt ? .accentBlue : .primaryOrange)
                .frame(width: 36, height: 36)
                .background((record.source == .receipt ? Color.accentBlue : Color.primaryOrange).opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(record.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 5) {
                    Text(record.date, style: .date)
                    Text("•")
                    Text(record.source == .receipt ? "Bill photo" : "Manual")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(currency(record.amount))
                    .font(.subheadline.weight(.bold))
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 14)
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

struct LoansTrackerView: View {
    @EnvironmentObject var store: AppStore
    @FocusState private var focusedField: LoanField?
    @State private var loanName = ""
    @State private var loanAmount = ""
    @State private var interestRate = ""
    @State private var paymentAmount = ""
    @State private var selectedLoanID: UUID?
    @State private var showPaymentSheet = false
    @State private var showEditSheet = false
    @State private var editingLoanID: UUID?
    @State private var editLoanName = ""
    @State private var editLoanAmount = ""
    @State private var editInterestRate = ""
    @State private var editPaidAmount = ""

    private var totalTaken: Double {
        store.loans.reduce(0) { $0 + $1.amountTaken }
    }

    private var totalPaid: Double {
        store.loans.reduce(0) { $0 + $1.amountPaid }
    }

    private var totalRemaining: Double {
        max(0, totalTaken - totalPaid)
    }

    private var monthlyDueTotal: Double {
        store.loans.reduce(0) { $0 + $1.monthlyDue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Loans")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Track borrowed amounts, repayments, balances, and monthly commitments.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Portfolio summary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SummaryPill(title: "Total Taken", value: currency(totalTaken), accent: .primaryOrange)
                            SummaryPill(title: "Total paid", value: currency(totalPaid), accent: .green)
                            SummaryPill(title: "Amount pending", value: currency(totalRemaining), accent: .accentBlue)
                            SummaryPill(title: "Monthly due", value: currency(monthlyDueTotal), accent: .purple)
                        }
                    }
                    .padding(14)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryOrange.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.primaryOrange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a new loan")
                                    .font(.headline)
                                Text("Track the principal and interest in one place.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(spacing: 12) {
                            TextField("Loan name", text: $loanName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                            HStack(spacing: 12) {
                                TextField("Amount taken", text: $loanAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .amount)
                                TextField("Rate %", text: $interestRate)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .rate)
                            }
                            Button(action: addLoan) {
                                Label("Add loan", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primaryOrange)
                            .disabled(loanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loanAmount.isEmpty || interestRate.isEmpty)
                        }
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.primaryOrange.opacity(0.12), Color.appCardBackground]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your loans")
                                .font(.headline)
                            Spacer()
                            Text("Balance: \(currency(totalRemaining))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        if store.loans.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "banknote.fill")
                                    .font(.title)
                                    .foregroundColor(.primaryOrange)
                                Text("No loans added yet")
                                    .font(.subheadline.weight(.semibold))
                                Text("Add your first loan and track every payment as it happens.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.appCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            ForEach(store.loans) { loan in
                                LoanRowView(
                                    loan: loan,
                                    onEdit: {
                                        editingLoanID = loan.id
                                        editLoanName = loan.name
                                        editLoanAmount = String(format: "%.2f", loan.amountTaken)
                                        editInterestRate = String(format: "%.2f", loan.interestRate)
                                        editPaidAmount = String(format: "%.2f", loan.amountPaid)
                                        showEditSheet = true
                                    },
                                    onDelete: {
                                        store.deleteLoan(loan)
                                    },
                                    onAddPayment: {
                                        selectedLoanID = loan.id
                                        paymentAmount = ""
                                        showPaymentSheet = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .sheet(isPresented: $showPaymentSheet) {
                PaymentSheet(
                    amountText: $paymentAmount,
                    onSave: {
                        guard let selectedLoanID else { return }
                        if let amount = Double(paymentAmount), amount > 0 {
                            store.addPayment(to: selectedLoanID, amount: amount)
                        }
                        showPaymentSheet = false
                    }
                )
            }
            .sheet(isPresented: $showEditSheet) {
                EditLoanSheet(
                    name: $editLoanName,
                    amount: $editLoanAmount,
                    rate: $editInterestRate,
                    paidAmount: $editPaidAmount,
                    onSave: {
                        guard let editingLoanID,
                              let amount = Double(editLoanAmount),
                              let rate = Double(editInterestRate),
                              let paidAmount = Double(editPaidAmount),
                              amount >= 0, paidAmount >= 0 else { return }

                        let updated = Loan(
                            id: editingLoanID,
                            name: editLoanName.trimmingCharacters(in: .whitespacesAndNewlines),
                            amountTaken: amount,
                            interestRate: rate,
                            amountPaid: min(paidAmount, amount)
                        )
                        store.updateLoan(updated)
                        showEditSheet = false
                    }
                )
            }
        }
    }

    private func addLoan() {
        let cleanedName = loanName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty,
              let amount = Double(loanAmount),
              let rate = Double(interestRate),
              amount >= 0 else { return }

        let loan = Loan(name: cleanedName, amountTaken: amount, interestRate: rate)
        store.addLoan(loan)
        focusedField = nil
        loanName = ""
        loanAmount = ""
        interestRate = ""
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private enum LoanField: Hashable {
    case name
    case amount
    case rate
}

private struct SummaryPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct LoanRowView: View {
    let loan: Loan
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAddPayment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loan.name)
                        .font(.headline)
                    Text("Rate: \(String(format: "%.1f", loan.interestRate))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                LoanStatusBadge(loan: loan)
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.primaryOrange)
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.fill")
                }
            }

            HStack(spacing: 12) {
                LoanStat(label: "Pending", value: currency(loan.remainingBalance))
                LoanStat(label: "Monthly due", value: currency(loan.monthlyDue))
                LoanStat(label: "Paid", value: currency(loan.amountPaid))
            }

            HStack(spacing: 8) {
                Button(action: onAddPayment) {
                    Label("Add payment", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private struct LoanStatusBadge: View {
    let loan: Loan

    var body: some View {
        if loan.remainingBalance <= 0 {
            Text("Paid fully")
                .font(.caption2.weight(.bold))
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
        } else if loan.monthlyDue > 0 {
            Text("Active")
                .font(.caption2.weight(.bold))
                .foregroundColor(.primaryOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primaryOrange.opacity(0.12))
                .clipShape(Capsule())
        } else {
            Text("Low due")
                .font(.caption2.weight(.bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

private struct LoanStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PaymentSheet: View {
    @Binding var amountText: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add loan payment")) {
                    TextField("Payment amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { amountText = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        amountText = ""
                    }
                    .disabled(Double(amountText) == nil || Double(amountText)! <= 0)
                }
            }
        }
    }
}

private struct EditLoanSheet: View {
    @Binding var name: String
    @Binding var amount: String
    @Binding var rate: String
    @Binding var paidAmount: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit loan")) {
                    TextField("Loan name", text: $name)
                    TextField("Amount taken", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Rate %", text: $rate)
                        .keyboardType(.decimalPad)
                    TextField("Amount paid", text: $paidAmount)
                        .keyboardType(.decimalPad)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        name = ""
                        amount = ""
                        rate = ""
                        paidAmount = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(amount) == nil || Double(rate) == nil)
                }
            }
        }
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
    @FocusState private var focusedField: ScanField?
    @State private var showingPicker = false
    @State private var pickedImage: UIImage?
    @State private var analysis: (calories:Int, carbs:Int, protein:Int, fats:Int)? = nil
    @State private var name = "Scanned Food"
    @State private var isAnalyzing = false
    @State private var scanMessage = ""
    @State private var manualMealText = ""
    @State private var mealDate = Date()
    @State private var manualMealName = ""
    @State private var manualCalories = ""
    @State private var manualCarbs = ""
    @State private var manualProtein = ""
    @State private var manualFats = ""
    @State private var manualEntryMessage = ""
    @State private var selectedEntryMethod: MealEntryMethod = .photo

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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a meal")
                            .font(.headline)
                        HStack(spacing: 8) {
                            ForEach(MealEntryMethod.allCases) { method in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedEntryMethod = method
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: method.icon)
                                            .font(.headline)
                                        Text(method.title)
                                            .font(.caption.weight(.semibold))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 68)
                                    .foregroundColor(selectedEntryMethod == method ? .white : .primary)
                                    .background(selectedEntryMethod == method ? Color.accentBlue : Color.appCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(method.title)
                            }
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 16) {
                        if selectedEntryMethod == .photo, let img = pickedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else if selectedEntryMethod == .photo {
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
                        if selectedEntryMethod == .photo {
                            Button(action: { showingPicker = true }) {
                                Label(pickedImage == nil ? "Choose food photo" : "Replace photo", systemImage: "camera.fill")
                                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primaryOrange)
                        }

                        if selectedEntryMethod == .description {
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
                            .focused($focusedField, equals: .manualMeal)
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
                        }

                        if selectedEntryMethod == .manual {
                            VStack(alignment: .leading, spacing: 12) {
                            Label("Enter meal manually", systemImage: "square.and.pencil")
                                .font(.subheadline.weight(.semibold))

                            RegistrationInputField(title: "Meal name", placeholder: "e.g. Chicken rice bowl", icon: "fork.knife", text: $manualMealName)

                            DatePicker("Meal date", selection: $mealDate, displayedComponents: .date)

                            HStack(spacing: 10) {
                                NutritionEntryField(title: "Calories", placeholder: "0", unit: "kcal", text: $manualCalories)
                                NutritionEntryField(title: "Carbs", placeholder: "0", unit: "g", text: $manualCarbs)
                            }
                            HStack(spacing: 10) {
                                NutritionEntryField(title: "Protein", placeholder: "0", unit: "g", text: $manualProtein)
                                NutritionEntryField(title: "Fats", placeholder: "0", unit: "g", text: $manualFats)
                            }

                            if !manualEntryMessage.isEmpty {
                                Text(manualEntryMessage)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            Button(action: submitManualEntry) {
                                Label("Submit meal", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentBlue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

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
                            DatePicker("Meal date", selection: $mealDate, displayedComponents: .date)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ScanNutritionTile(title: "Calories", value: "\(a.calories)", unit: "kcal", color: .primaryOrange)
                                ScanNutritionTile(title: "Protein", value: "\(a.protein)", unit: "g", color: .accentBlue)
                                ScanNutritionTile(title: "Carbs", value: "\(a.carbs)", unit: "g", color: .green)
                                ScanNutritionTile(title: "Fats", value: "\(a.fats)", unit: "g", color: .purple)
                            }
                            Button(action: {
                                let entry = FoodEntry(date: mealDate, name: name, calories: a.calories, carbsGrams: a.carbs, proteinGrams: a.protein, fatsGrams: a.fats, source: .photo)
                                store.addEntry(entry)
                                focusedField = nil
                                pickedImage = nil
                                analysis = nil
                                manualMealText = ""
                                mealDate = Date()
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

        focusedField = nil

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

    private func submitManualEntry() {
        let trimmedName = manualMealName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let calories = Int(manualCalories), calories >= 0,
              let carbs = Int(manualCarbs), carbs >= 0,
              let protein = Int(manualProtein), protein >= 0,
              let fats = Int(manualFats), fats >= 0 else {
            manualEntryMessage = "Enter a meal name and non-negative whole numbers for all nutrition values."
            return
        }

        store.addEntry(FoodEntry(
            date: mealDate,
            name: trimmedName,
            calories: calories,
            carbsGrams: carbs,
            proteinGrams: protein,
            fatsGrams: fats,
            source: .manual
        ))
        manualMealName = ""
        manualCalories = ""
        manualCarbs = ""
        manualProtein = ""
        manualFats = ""
        manualEntryMessage = ""
        mealDate = Date()
    }
}

private enum MealEntryMethod: String, CaseIterable, Identifiable {
    case photo
    case description
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: return "Upload photo"
        case .description: return "Describe meal"
        case .manual: return "Enter manually"
        }
    }

    var icon: String {
        switch self {
        case .photo: return "camera.fill"
        case .description: return "text.badge.checkmark"
        case .manual: return "square.and.pencil"
        }
    }
}

private enum ScanField: Hashable {
    case manualMeal
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

struct NutritionEntryField: View {
    let title: String
    let placeholder: String
    let unit: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 58)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentBlue.opacity(text.isEmpty ? 0.12 : 0.55), lineWidth: 1.5))
    }
}

struct TrackerView: View {
    @EnvironmentObject var store: AppStore
    @State private var editingEntry: FoodEntry?
    @State private var editedName = ""
    @State private var editedCalories = ""
    @State private var editedProtein = ""
    @State private var editedCarbs = ""
    @State private var editedFats = ""

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
                                TrackerMealRow(
                                    entry: entry,
                                    onEdit: {
                                        editingEntry = entry
                                        editedName = entry.name
                                        editedCalories = String(entry.calories)
                                        editedProtein = String(entry.proteinGrams)
                                        editedCarbs = String(entry.carbsGrams)
                                        editedFats = String(entry.fatsGrams)
                                    },
                                    onDelete: { store.deleteEntry(entry) }
                                )
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
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                Form {
                    Section(header: Text("Edit meal")) {
                        TextField("Meal name", text: $editedName)
                        TextField("Calories", text: $editedCalories)
                            .keyboardType(.numberPad)
                        TextField("Protein (g)", text: $editedProtein)
                            .keyboardType(.numberPad)
                        TextField("Carbs (g)", text: $editedCarbs)
                            .keyboardType(.numberPad)
                        TextField("Fats (g)", text: $editedFats)
                            .keyboardType(.numberPad)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            editingEntry = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard let edited = editingEntry,
                                  !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  let calories = Int(editedCalories),
                                  let protein = Int(editedProtein),
                                  let carbs = Int(editedCarbs),
                                  let fats = Int(editedFats) else { return }

                            let updated = FoodEntry(
                                id: edited.id,
                                date: edited.date,
                                name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                                calories: calories,
                                carbsGrams: carbs,
                                proteinGrams: protein,
                                fatsGrams: fats,
                                source: edited.source
                            )
                            store.updateEntry(updated)
                            editingEntry = nil
                        }
                    }
                }
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
    let entry: FoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.primaryOrange)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 14)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)

            Button(role: .destructive) {
                onDelete()
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
                        WaterMinusButton(amount: 250, action: { minusWater(250) })
                        WaterAddButton(amount: 250, action: { addWater(250) })
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
    @State private var isExportingBudget = false
    @State private var budgetExportDocument = BudgetCSVDocument()
    @State private var isExportingLoans = false
    @State private var loansExportDocument = LoansCSVDocument()

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

                            VStack(alignment: .leading, spacing: 14) {
                                Label("Budget history", systemImage: "chart.pie.fill")
                                    .font(.headline)
                                Text("Download your spending records with dates, amounts, and entry sources.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    budgetExportDocument = BudgetCSVDocument(records: store.budgetRecords)
                                    isExportingBudget = true
                                }) {
                                    Label("Download budget CSV", systemImage: "arrow.down.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primaryOrange)
                                .disabled(store.budgetRecords.isEmpty)
                                if store.budgetRecords.isEmpty {
                                    Text("Add a spending record before downloading your budget history.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            VStack(alignment: .leading, spacing: 14) {
                                Label("Loans history", systemImage: "banknote.fill")
                                    .font(.headline)
                                Text("Download loan balances, repayments, and interest details in one file.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    loansExportDocument = LoansCSVDocument(loans: store.loans)
                                    isExportingLoans = true
                                }) {
                                    Label("Download loans CSV", systemImage: "arrow.down.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .tint(.accentBlue)
                                .disabled(store.loans.isEmpty)
                                if store.loans.isEmpty {
                                    Text("Add a loan before downloading your loan history.")
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
            defaultFilename: "massist-nutrition-history"
        ) { _ in }
        .fileExporter(
            isPresented: $isExportingBudget,
            document: budgetExportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "massist-budget-history"
        ) { _ in }
        .fileExporter(
            isPresented: $isExportingLoans,
            document: loansExportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "massist-loans-history"
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

    var data: Data { Data(contents.utf8) }

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

struct BudgetCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    private var contents: String

    var data: Data { Data(contents.utf8) }

    init() {
        contents = "Date,Name,Amount,Source\n"
    }

    init(records: [BudgetRecord]) {
        let formatter = ISO8601DateFormatter()
        let rows = records.sorted { $0.date < $1.date }.map { record in
            [
                formatter.string(from: record.date),
                Self.escape(record.name),
                String(format: "%.2f", record.amount),
                record.source == .receipt ? "Receipt photo" : "Manual"
            ].joined(separator: ",")
        }
        contents = (["Date,Name,Amount,Source"] + rows).joined(separator: "\n") + "\n"
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

struct LoansCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    private var contents: String

    var data: Data { Data(contents.utf8) }

    init() {
        contents = "Name,Amount Taken,Interest Rate (%),Amount Paid,Remaining Balance,Monthly Due\n"
    }

    init(loans: [Loan]) {
        let rows = loans.map { loan in
            [
                Self.escape(loan.name),
                String(format: "%.2f", loan.amountTaken),
                String(format: "%.2f", loan.interestRate),
                String(format: "%.2f", loan.amountPaid),
                String(format: "%.2f", loan.remainingBalance),
                String(format: "%.2f", loan.monthlyDue)
            ].joined(separator: ",")
        }
        contents = (["Name,Amount Taken,Interest Rate (%),Amount Paid,Remaining Balance,Monthly Due"] + rows).joined(separator: "\n") + "\n"
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
    @AppStorage("waterIntakeML") private var waterIntakeML = 0
    @AppStorage("waterNotificationsEnabled") private var notificationsEnabled = true
    @AppStorage("waterGoalML") private var waterGoalML = 3000
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var geminiAPIKey = ""
    @State private var saved = false
    @State private var reportMessage = ""
    @State private var mailReport: MailReport?
    @State private var isPreparingReport = false
    private let pedometer = CMPedometer()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Settings").font(.system(size: min(32, max(24, geometry.size.width * 0.08)), weight: .bold, design: .rounded))
                            Text("Make MAssist fit your workday.").font(.subheadline).foregroundColor(.secondary)
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
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Your report", systemImage: "envelope.badge.fill").font(.headline)
                            Text("Send nutrition, budget, loan, water, and step details to your registered email.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button(action: {
                                Task { await sendMonthlyReport() }
                            }) {
                                Label("Send details to me", systemImage: "paperplane.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentBlue)
                            .disabled(isPreparingReport || store.profile?.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                            if !reportMessage.isEmpty {
                                Text(reportMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
        .sheet(item: $mailReport) { report in
            MailComposeView(
                recipient: report.recipient,
                subject: report.subject,
                body: report.body,
                attachments: report.attachments
            )
        }
    }

    private func saveSettings() {
        guard var profile = store.profile else { return }
        let key = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.geminiAPIKey = key.isEmpty ? nil : key
        store.saveProfile(profile)
        saved = true
    }

    private func sendMonthlyReport() async {
                guard !isPreparingReport else { return }
        guard let profile = store.profile,
              !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run { reportMessage = "Add an email address to your profile first." }
            return
        }
        guard MFMailComposeViewController.canSendMail() else {
            await MainActor.run { reportMessage = "Mail is not configured on this device. Set up Apple Mail and try again." }
            return
        }

        await MainActor.run {
            isPreparingReport = true
            reportMessage = "Preparing your report..."
        }
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let monthEntries = store.entries.filter { $0.date >= monthStart }
        let monthBudget = store.budgetRecords.filter { $0.date >= monthStart }
        let steps = await monthlySteps(from: monthStart, to: Date())
        let budgetTotal = monthBudget.reduce(0) { $0 + $1.amount }
        let nutritionCalories = monthEntries.reduce(0) { $0 + $1.calories }
        let nutritionProtein = monthEntries.reduce(0) { $0 + $1.proteinGrams }
        let nutritionCarbs = monthEntries.reduce(0) { $0 + $1.carbsGrams }
        let nutritionFats = monthEntries.reduce(0) { $0 + $1.fatsGrams }
        let averageWeeklySpend = budgetTotal / max(1, Double(calendar.dateComponents([.weekOfYear], from: monthStart, to: Date()).weekOfYear ?? 1))
        let monthName = monthStart.formatted(.dateTime.month(.wide).year())
        let dateLabel = Date().formatted(.dateTime.year().month().day())
        let subject = "MAssist - Weekly report - \(dateLabel)"

        let prompt = """
        Write a concise, friendly personal health and finance report for \(monthName). Use plain text with short headings and bullet points. Do not invent data. Mention average weekly spending, total monthly spending, nutrition totals, water intake currently recorded, loan totals, and steps. End with one practical observation. Here is the data:
        Average weekly spending: \(currency(averageWeeklySpend))
        Total monthly spending: \(currency(budgetTotal))
        Nutrition entries: \(monthEntries.count), calories: \(nutritionCalories) kcal, protein: \(nutritionProtein) g, carbs: \(nutritionCarbs) g, fats: \(nutritionFats) g
        Water currently recorded: \(String(format: "%.1f", Double(waterIntakeML) / 1000.0)) L
        Steps this month: \(steps)
        Loans total taken: \(currency(store.loans.reduce(0) { $0 + $1.amountTaken }))
        Loans total paid: \(currency(store.loans.reduce(0) { $0 + $1.amountPaid }))
        """

        let summary: String
        if let key = profile.geminiAPIKey, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            summary = (try? await GeminiNutritionService().generateReportSummary(prompt: prompt, apiKey: key)) ?? localReportSummary(monthName: monthName, averageWeeklySpend: averageWeeklySpend, budgetTotal: budgetTotal, calories: nutritionCalories, protein: nutritionProtein, carbs: nutritionCarbs, fats: nutritionFats, steps: steps)
        } else {
            summary = localReportSummary(monthName: monthName, averageWeeklySpend: averageWeeklySpend, budgetTotal: budgetTotal, calories: nutritionCalories, protein: nutritionProtein, carbs: nutritionCarbs, fats: nutritionFats, steps: steps)
        }

        let nutritionCSV = NutritionCSVDocument(entries: store.entries)
        let budgetCSV = BudgetCSVDocument(records: store.budgetRecords)
        let loansCSV = LoansCSVDocument(loans: store.loans)
        await MainActor.run {
            mailReport = MailReport(
                recipient: profile.email,
                subject: subject,
                body: summary,
                attachments: [
                    MailAttachment(data: nutritionCSV.data, filename: "massist-nutrition-history.csv"),
                    MailAttachment(data: budgetCSV.data, filename: "massist-budget-history.csv"),
                    MailAttachment(data: loansCSV.data, filename: "massist-loans-history.csv")
                ]
            )
            isPreparingReport = false
            reportMessage = ""
        }
    }

    private func monthlySteps(from start: Date, to end: Date) async -> Int {
        guard CMPedometer.isStepCountingAvailable() else { return 0 }
        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                continuation.resume(returning: data?.numberOfSteps.intValue ?? 0)
            }
        }
    }

    private func localReportSummary(monthName: String, averageWeeklySpend: Double, budgetTotal: Double, calories: Int, protein: Int, carbs: Int, fats: Int, steps: Int) -> String {
        "MAssist report - \(monthName)\n\nSpending\n• Monthly spending: \(currency(budgetTotal))\n• Average weekly spending: \(currency(averageWeeklySpend))\n\nNutrition\n• Calories: \(calories) kcal\n• Protein: \(protein) g | Carbs: \(carbs) g | Fats: \(fats) g\n• Water currently recorded: \(String(format: "%.1f", Double(waterIntakeML) / 1000.0)) L\n\nActivity\n• Steps this month: \(steps)\n\nLoan totals are included in the attached CSV."
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

private struct MailAttachment {
    let data: Data
    let filename: String
}

private struct MailReport: Identifiable {
    let id = UUID()
    let recipient: String
    let subject: String
    let body: String
    let attachments: [MailAttachment]
}

private struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    let attachments: [MailAttachment]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            controller.addAttachmentData(attachment.data, mimeType: "text/csv", fileName: attachment.filename)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
