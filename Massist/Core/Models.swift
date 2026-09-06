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
    var stepTarget: Int?
    var geminiAPIKey: String?

    init(name: String = "", email: String, gender: String? = nil, age: Int? = nil, weightKg: Double? = nil, heightCm: Double? = nil, goal: GoalType? = nil, calorieTarget: Int? = nil, proteinTarget: Int? = nil, fatTarget: Int? = nil, stepTarget: Int? = nil, geminiAPIKey: String? = nil) {
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
        self.stepTarget = stepTarget
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

struct Loan: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var amountTaken: Double
    var interestRate: Double
    var amountPaid: Double

    var remainingBalance: Double {
        max(0, amountTaken - amountPaid)
    }

    var monthlyDue: Double {
        let monthlyRate = (interestRate / 100.0) / 12.0
        return max(0, remainingBalance) * monthlyRate
    }

    init(id: UUID = UUID(), name: String, amountTaken: Double, interestRate: Double, amountPaid: Double = 0) {
        self.id = id
        self.name = name
        self.amountTaken = max(0, amountTaken)
        self.interestRate = max(0, interestRate)
        self.amountPaid = max(0, amountPaid)
    }
}

enum BudgetRecordSource: String, Codable {
    case receipt
    case manual
}

struct BudgetRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var date: Date
    var name: String
    var amount: Double
    var source: BudgetRecordSource

    init(id: UUID = UUID(), date: Date = Date(), name: String, amount: Double, source: BudgetRecordSource = .manual) {
        self.id = id
        self.date = date
        self.name = name
        self.amount = max(0, amount)
        self.source = source
    }
}
