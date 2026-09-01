import Foundation

enum GoalType: String, Codable, CaseIterable {
    case maintain
    case muscleGain
    case weightLoss
}

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var gender: String?
    var age: Int?
    var weightKg: Double?
    var heightCm: Double?
    var goal: GoalType?
    var calorieTarget: Int?
    var proteinTarget: Int?
    var fatTarget: Int?
    var geminiAPIKey: String?

    init(name: String = "", email: String, gender: String? = nil, age: Int? = nil, weightKg: Double? = nil, heightCm: Double? = nil, goal: GoalType? = nil, calorieTarget: Int? = nil, proteinTarget: Int? = nil, fatTarget: Int? = nil, geminiAPIKey: String? = nil) {
        self.name = name
        self.email = email
        self.gender = gender
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.goal = goal
        self.calorieTarget = calorieTarget
        self.proteinTarget = proteinTarget
        self.fatTarget = fatTarget
        self.geminiAPIKey = geminiAPIKey
    }
}

enum EntrySource: String, Codable {
    case photo
    case manual
}

struct FoodEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var date: Date
    var name: String
    var calories: Int
    var carbsGrams: Int
    var proteinGrams: Int
    var fatsGrams: Int
    var source: EntrySource

    init(id: UUID = UUID(), date: Date = Date(), name: String, calories: Int, carbsGrams: Int, proteinGrams: Int, fatsGrams: Int, source: EntrySource = .photo) {
        self.id = id
        self.date = date
        self.name = name
        self.calories = calories
        self.carbsGrams = carbsGrams
        self.proteinGrams = proteinGrams
        self.fatsGrams = fatsGrams
        self.source = source
    }
}
