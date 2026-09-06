//
//  ManagedObjects.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import Foundation
import CoreData

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var email: String
    @NSManaged public var gender: String?
    @NSManaged public var age: Int16
    @NSManaged public var weightKg: Double
    @NSManaged public var heightCm: Double
    @NSManaged public var goal: String
    @NSManaged public var calorieTarget: NSNumber?
    @NSManaged public var proteinTarget: NSNumber?
    @NSManaged public var fatTarget: NSNumber?
    @NSManaged public var stepTarget: NSNumber?
    @NSManaged public var geminiAPIKey: String?
}

@objc(CDFoodEntry)
public class CDFoodEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var name: String
    @NSManaged public var calories: Int32
    @NSManaged public var carbsGrams: Int32
    @NSManaged public var proteinGrams: Int32
    @NSManaged public var fatsGrams: Int32
    @NSManaged public var source: String
}

extension CDUserProfile {
    static func create(from model: UserProfile, in context: NSManagedObjectContext) -> CDUserProfile {
        let obj = CDUserProfile(context: context)
        obj.name = model.name
        obj.email = model.email
        obj.age = Int16(model.age ?? 0)
        obj.weightKg = model.weightKg ?? 0
        obj.heightCm = model.heightCm ?? 0
        obj.goal = (model.goal ?? .maintain).rawValue
        obj.gender = model.gender
        obj.calorieTarget = model.calorieTarget.map(NSNumber.init(value:))
        obj.proteinTarget = model.proteinTarget.map(NSNumber.init(value:))
        obj.fatTarget = model.fatTarget.map(NSNumber.init(value:))
        obj.stepTarget = model.stepTarget.map(NSNumber.init(value:))
        obj.geminiAPIKey = model.geminiAPIKey
        return obj
    }

    func toModel() -> UserProfile {
        var up = UserProfile(name: name ?? "", email: email, gender: gender)
        up.age = age == 0 ? nil : Int(age)
        up.weightKg = weightKg == 0 ? nil : weightKg
        up.heightCm = heightCm == 0 ? nil : heightCm
        up.goal = GoalType(rawValue: goal) ?? .maintain
        up.calorieTarget = calorieTarget?.intValue
        up.proteinTarget = proteinTarget?.intValue
        up.fatTarget = fatTarget?.intValue
        up.stepTarget = stepTarget?.intValue
        up.geminiAPIKey = geminiAPIKey
        return up
    }
}

extension CDFoodEntry {
    static func create(from model: FoodEntry, in context: NSManagedObjectContext) -> CDFoodEntry {
        let obj = CDFoodEntry(context: context)
        obj.id = model.id
        obj.date = model.date
        obj.name = model.name
        obj.calories = Int32(model.calories)
        obj.carbsGrams = Int32(model.carbsGrams)
        obj.proteinGrams = Int32(model.proteinGrams)
        obj.fatsGrams = Int32(model.fatsGrams)
        obj.source = model.source.rawValue
        return obj
    }

    func toModel() -> FoodEntry {
        let resolvedSource = source.isEmpty ? EntrySource.photo : (EntrySource(rawValue: source) ?? .photo)
        return FoodEntry(id: id, date: date, name: name, calories: Int(calories), carbsGrams: Int(carbsGrams), proteinGrams: Int(proteinGrams), fatsGrams: Int(fatsGrams), source: resolvedSource)
    }
}

