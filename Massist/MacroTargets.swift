//
//  MacroTargets.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//


import Foundation
import UIKit
import CryptoKit

struct MacroTargets {
    var calories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatsGrams: Int
}

class MacroCalculator {
    // Mifflin-St Jeor BMR
    static func bmr(weightKg: Double, heightCm: Double, age: Int, male: Bool = false) -> Double {
        // using female by default; user can adapt
        let s = male ? 5.0 : -161.0
        return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + s
    }

    static func targets(for profile: UserProfile) -> MacroTargets {
        guard let w = profile.weightKg, let h = profile.heightCm, let a = profile.age else {
            let calories = profile.calorieTarget ?? 2000
            let protein = profile.proteinTarget ?? 75
            let fats = profile.fatTarget ?? 55
            return MacroTargets(calories: calories, proteinGrams: protein, carbsGrams: max(0, (calories - protein * 4 - fats * 9) / 4), fatsGrams: fats)
        }
        let baseBMR = bmr(weightKg: w, heightCm: h, age: a)
        // assume sedentary activity for now
        let tdee = baseBMR * 1.2
        var calories = Int(tdee)
        var protein = Int((1.4 * w).rounded())
        switch profile.goal {
        case .muscleGain:
            calories = Int(tdee + 300)
            protein = Int((2.0 * w).rounded())
        case .weightLoss:
            calories = Int(max(1200, tdee - 500))
            protein = Int((1.6 * w).rounded())
        default:
            break
        }
        let fats = Int((Double(calories) * 0.25 / 9.0).rounded())
        let finalCalories = profile.calorieTarget ?? calories
        let finalProtein = profile.proteinTarget ?? protein
        let finalFats = profile.fatTarget ?? fats
        let carbs = max(0, (finalCalories - finalProtein * 4 - finalFats * 9) / 4)
        return MacroTargets(calories: finalCalories, proteinGrams: finalProtein, carbsGrams: carbs, fatsGrams: finalFats)
    }

    // Mock image analysis: deterministic pseudo-random numbers based on image data hash
    static func analyzeImage(_ uiImage: UIImage) -> (calories: Int, carbs: Int, protein: Int, fats: Int) {
        guard let data = uiImage.pngData() else {
            return (250, 30, 20, 10)
        }
        let digest = SHA256.hash(data: data)
        let hex = digest.withUnsafeBytes { ptr -> UInt64 in
            var v: UInt64 = 0
            for i in 0..<min(8, ptr.count) {
                v = (v << 8) | UInt64(ptr[i])
            }
            return v
        }
        // calories between 120 and 900
        let calories = Int(120 + (hex % 780))
        // base macro distribution: carbs 50%, protein 25%, fats 25%
        let carbsCal = Double(calories) * 0.5
        let proteinCal = Double(calories) * 0.25
        let fatsCal = Double(calories) * 0.25
        // convert to grams
        let carbs = Int((carbsCal / 4.0).rounded())
        let protein = Int((proteinCal / 4.0).rounded())
        let fats = Int((fatsCal / 9.0).rounded())
        return (calories, carbs, protein, fats)
    }
}
