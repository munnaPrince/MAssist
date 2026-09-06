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
    @Published var loans: [Loan] = [] {
        didSet { saveLoans() }
    }
    @Published var budgetRecords: [BudgetRecord] = [] {
        didSet { saveBudgetRecords() }
    }

    private let service: DataService
    private let loansKey = "massist.loans"
    private let budgetRecordsKey = "massist.budgetRecords"

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

    func updateEntry(_ updated: FoodEntry) {
        do {
            try service.updateEntry(updated)
            if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                entries[index] = updated
            }
        } catch {
            print("Failed to update entry: \(error)")
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

    func addLoan(_ loan: Loan) {
        loans.insert(loan, at: 0)
    }

    func updateLoan(_ updatedLoan: Loan) {
        if let idx = loans.firstIndex(where: { $0.id == updatedLoan.id }) {
            loans[idx] = updatedLoan
        }
    }

    func deleteLoan(_ loan: Loan) {
        loans.removeAll { $0.id == loan.id }
    }

    func addPayment(to loanId: UUID, amount: Double) {
        guard amount > 0 else { return }
        if let idx = loans.firstIndex(where: { $0.id == loanId }) {
            let currentLoan = loans[idx]
            let maxAllowed = max(0, currentLoan.amountTaken - currentLoan.amountPaid)
            loans[idx].amountPaid = min(currentLoan.amountTaken, currentLoan.amountPaid + min(amount, maxAllowed))
        }
    }

    func addBudgetRecord(_ record: BudgetRecord) {
        budgetRecords.insert(record, at: 0)
    }

    func deleteBudgetRecord(_ record: BudgetRecord) {
        budgetRecords.removeAll { $0.id == record.id }
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
        loadLoans()
        loadBudgetRecords()
    }

    private func loadLoans() {
        guard let data = UserDefaults.standard.data(forKey: loansKey) else {
            loans = []
            return
        }

        if let decoded = try? JSONDecoder().decode([Loan].self, from: data) {
            loans = decoded
        } else {
            loans = []
        }
    }

    private func saveLoans() {
        guard let data = try? JSONEncoder().encode(loans) else { return }
        UserDefaults.standard.set(data, forKey: loansKey)
    }

    private func loadBudgetRecords() {
        guard let data = UserDefaults.standard.data(forKey: budgetRecordsKey) else {
            budgetRecords = []
            return
        }

        if let decoded = try? JSONDecoder().decode([BudgetRecord].self, from: data) {
            budgetRecords = decoded
        } else {
            budgetRecords = []
        }
    }

    private func saveBudgetRecords() {
        guard let data = try? JSONEncoder().encode(budgetRecords) else { return }
        UserDefaults.standard.set(data, forKey: budgetRecordsKey)
    }
}
