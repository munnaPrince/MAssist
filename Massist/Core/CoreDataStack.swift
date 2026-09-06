//
//  CoreDataStack.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        let model = Self.createModel()
        container = NSPersistentContainer(name: "MAssistModel", managedObjectModel: model)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { desc, error in
            if let err = error {
                fatalError("Core Data failed to load: \(err)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // UserProfile entity
        let user = NSEntityDescription()
        user.name = "CDUserProfile"
        user.managedObjectClassName = "CDUserProfile"
        var userProperties: [NSAttributeDescription] = []

        let userNameAttr = NSAttributeDescription()
        userNameAttr.name = "name"
        userNameAttr.attributeType = .stringAttributeType
        userNameAttr.isOptional = true
        userProperties.append(userNameAttr)

        let emailAttr = NSAttributeDescription()
        emailAttr.name = "email"
        emailAttr.attributeType = .stringAttributeType
        emailAttr.isOptional = false
        userProperties.append(emailAttr)

        let genderAttr = NSAttributeDescription()
        genderAttr.name = "gender"
        genderAttr.attributeType = .stringAttributeType
        genderAttr.isOptional = true
        userProperties.append(genderAttr)

        let ageAttr = NSAttributeDescription()
        ageAttr.name = "age"
        ageAttr.attributeType = .integer16AttributeType
        ageAttr.isOptional = true
        userProperties.append(ageAttr)

        let weightAttr = NSAttributeDescription()
        weightAttr.name = "weightKg"
        weightAttr.attributeType = .doubleAttributeType
        weightAttr.isOptional = true
        userProperties.append(weightAttr)

        let heightAttr = NSAttributeDescription()
        heightAttr.name = "heightCm"
        heightAttr.attributeType = .doubleAttributeType
        heightAttr.isOptional = true
        userProperties.append(heightAttr)

        let goalAttr = NSAttributeDescription()
        goalAttr.name = "goal"
        goalAttr.attributeType = .stringAttributeType
        goalAttr.isOptional = false
        goalAttr.defaultValue = "maintain"
        userProperties.append(goalAttr)

        func optionalIntAttr(_ name: String) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = .integer32AttributeType
            attribute.isOptional = true
            return attribute
        }

        userProperties.append(optionalIntAttr("calorieTarget"))
        userProperties.append(optionalIntAttr("proteinTarget"))
        userProperties.append(optionalIntAttr("fatTarget"))
        userProperties.append(optionalIntAttr("stepTarget"))

        let geminiAPIKeyAttr = NSAttributeDescription()
        geminiAPIKeyAttr.name = "geminiAPIKey"
        geminiAPIKeyAttr.attributeType = .stringAttributeType
        geminiAPIKeyAttr.isOptional = true
        userProperties.append(geminiAPIKeyAttr)

        user.properties = userProperties

        // FoodEntry entity
        let entry = NSEntityDescription()
        entry.name = "CDFoodEntry"
        entry.managedObjectClassName = "CDFoodEntry"
        var entryProperties: [NSAttributeDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        entryProperties.append(idAttr)

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        entryProperties.append(dateAttr)

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        entryProperties.append(nameAttr)

        func intAttr(_ name: String) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .integer32AttributeType
            a.isOptional = false
            return a
        }

        entryProperties.append(intAttr("calories"))
        entryProperties.append(intAttr("carbsGrams"))
        entryProperties.append(intAttr("proteinGrams"))
        entryProperties.append(intAttr("fatsGrams"))

        let sourceAttr = NSAttributeDescription()
        sourceAttr.name = "source"
        sourceAttr.attributeType = .stringAttributeType
        sourceAttr.isOptional = false
        sourceAttr.defaultValue = EntrySource.photo.rawValue
        entryProperties.append(sourceAttr)

        entry.properties = entryProperties

        model.entities = [user, entry]
        return model
    }
}
