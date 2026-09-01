//
//  Storage.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import Foundation
import SwiftUI
import Combine

class AppStore: ObservableObject {
    @Published var profile: UserProfile?
    @Published var loggedIn: Bool = false
    @Published var entries: [FoodEntry] = []

    private let service: DataService

    init(service: DataService = .shared) {
        self.service = service
        load()
    }

    func saveProfile(_ p: UserProfile) {
        do {
            try service.saveProfile(p)
            profile = p
            loggedIn = true
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    func addEntry(_ e: FoodEntry) {
        do {
            try service.addEntry(e)
            entries.insert(e, at: 0)
        } catch {
            print("Failed to add entry: \(error)")
        }
    }

    func deleteEntry(_ e: FoodEntry) {
        do {
            try service.deleteEntry(id: e.id)
            entries.removeAll { $0.id == e.id }
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }

    func logout() {
        profile = nil
        loggedIn = false
        // For production, consider clearing stores or handling tokens
    }

    private func load() {
        profile = service.fetchProfile()
        loggedIn = profile != nil
        entries = service.fetchEntries()
    }
}
