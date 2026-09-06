//
//  DataService.swift
//  MAssist
//
//  Created by Munnaf Koilakuntla on 28/08/26.
//

import Foundation
import CoreData
import UIKit

final class DataService {
    static let shared = DataService()
    private let container: NSPersistentContainer

    private init(container: NSPersistentContainer = CoreDataStack.shared.container) {
        self.container = container
    }

    var context: NSManagedObjectContext { container.viewContext }

    // MARK: - Profile
    func fetchProfile() -> UserProfile? {
        let req = NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
        req.fetchLimit = 1
        if let res = try? context.fetch(req), let cd = res.first {
            return cd.toModel()
        }
        return nil
    }

    func saveProfile(_ p: UserProfile) throws {
        // delete existing then create one
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "CDUserProfile")
        let del = NSBatchDeleteRequest(fetchRequest: req)
        _ = try context.execute(del)

        _ = CDUserProfile.create(from: p, in: context)
        try context.save()
    }

    // MARK: - Entries
    func fetchEntries() -> [FoodEntry] {
        let req = NSFetchRequest<CDFoodEntry>(entityName: "CDFoodEntry")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let res = (try? context.fetch(req)) ?? []
        return res.map { $0.toModel() }
    }

    func addEntry(_ e: FoodEntry) throws {
        _ = CDFoodEntry.create(from: e, in: context)
        try context.save()
    }

    func updateEntry(_ e: FoodEntry) throws {
        let req = NSFetchRequest<CDFoodEntry>(entityName: "CDFoodEntry")
        req.predicate = NSPredicate(format: "id == %@", e.id as CVarArg)
        let res = try context.fetch(req)
        if let existing = res.first {
            existing.date = e.date
            existing.name = e.name
            existing.calories = Int32(e.calories)
            existing.carbsGrams = Int32(e.carbsGrams)
            existing.proteinGrams = Int32(e.proteinGrams)
            existing.fatsGrams = Int32(e.fatsGrams)
            existing.source = e.source.rawValue
            try context.save()
        }
    }

    func deleteEntry(id: UUID) throws {
        let req = NSFetchRequest<CDFoodEntry>(entityName: "CDFoodEntry")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let res = try? context.fetch(req) {
            for obj in res { context.delete(obj) }
            try context.save()
        }
    }
}

enum GeminiNutritionError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: return "Add a Gemini API key in Profile before scanning."
        case .invalidResponse: return "Gemini returned an unreadable nutrition response."
        case .requestFailed(let message): return message
        }
    }
}

struct GeminiNutritionService {
    private struct Request: Encodable {
        struct Content: Encodable {
            struct Part: Encodable {
                let text: String?
                let inlineData: InlineData?
            }
            let parts: [Part]
        }
        struct InlineData: Encodable {
            let mimeType: String
            let data: String
        }
        let contents: [Content]
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String? }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]?
    }

    private struct Nutrition: Decodable {
        let name: String?
        let calories: Int
        let carbs: Int
        let protein: Int
        let fats: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            calories = try Self.decodeInt(container, key: .calories)
            carbs = try Self.decodeInt(container, key: .carbs)
            protein = try Self.decodeInt(container, key: .protein)
            fats = try Self.decodeInt(container, key: .fats)
        }

        private enum CodingKeys: String, CodingKey {
            case name, calories, carbs, protein, fats
        }

        private static func decodeInt<T: CodingKey>(_ container: KeyedDecodingContainer<T>, key: T) throws -> Int {
            if let value = try? container.decode(Int.self, forKey: key) {
                return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                return Int(value.rounded())
            }
            if let value = try? container.decode(String.self, forKey: key),
               let number = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return Int(number.rounded())
            }
            throw DecodingError.typeMismatch(
                Int.self,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected a number for nutrition value")
            )
        }
    }

    private struct Expense: Decodable {
        let name: String?
        let amount: Double
    }

    func analyzeReceipt(image: UIImage, apiKey: String) async throws -> (name: String, amount: Double) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiNutritionError.invalidAPIKey }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw GeminiNutritionError.invalidResponse }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(trimmedKey)")!
        let prompt = "Analyze this grocery or food bill. Return JSON only with exactly these keys: name (short merchant or purchase description), amount (total amount as a number). Use the final payable total, excluding currency symbols. No markdown or explanation."
        let requestBody = Request(contents: [.init(parts: [.init(text: prompt, inlineData: nil), .init(text: nil, inlineData: .init(mimeType: "image/jpeg", data: imageData.base64EncodedString()))])])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw GeminiNutritionError.requestFailed("Gemini took too long to respond. Try again with a smaller photo.")
        } catch {
            throw GeminiNutritionError.requestFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GeminiNutritionError.requestFailed("Gemini could not read this bill. Check your API key and try again.")
        }
        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decodedResponse.candidates?.first?.content.parts.first?.text else { throw GeminiNutritionError.invalidResponse }
        let cleanText = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let expense = try JSONDecoder().decode(Expense.self, from: Data(cleanText.utf8))
        guard expense.amount >= 0 else { throw GeminiNutritionError.invalidResponse }
        return (expense.name ?? "Scanned bill", expense.amount)
    }

    func analyze(image: UIImage, apiKey: String) async throws -> (name: String, calories: Int, carbs: Int, protein: Int, fats: Int) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiNutritionError.invalidAPIKey }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw GeminiNutritionError.invalidResponse }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(trimmedKey)")!
        let prompt = "Analyze the food in this image. Return JSON only with exactly these keys: name (string), calories (integer kcal), carbs (integer grams), protein (integer grams), fats (integer grams). Use reasonable estimates. No markdown or explanation."
        let requestBody = Request(contents: [.init(parts: [.init(text: prompt, inlineData: nil), .init(text: nil, inlineData: .init(mimeType: "image/jpeg", data: imageData.base64EncodedString()))])])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw GeminiNutritionError.requestFailed("Gemini took too long to respond. Try again with a smaller photo.")
        } catch {
            throw GeminiNutritionError.requestFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GeminiNutritionError.requestFailed("Gemini could not analyze this image. Check your API key and try again.")
        }
        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decodedResponse.candidates?.first?.content.parts.first?.text else { throw GeminiNutritionError.invalidResponse }
        let cleanText = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nutrition = try JSONDecoder().decode(Nutrition.self, from: Data(cleanText.utf8))
        return (nutrition.name ?? "Scanned Food", max(0, nutrition.calories), max(0, nutrition.carbs), max(0, nutrition.protein), max(0, nutrition.fats))
    }

    func analyzeText(description: String, apiKey: String) async throws -> (name: String, calories: Int, carbs: Int, protein: Int, fats: Int) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiNutritionError.invalidAPIKey }
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw GeminiNutritionError.invalidResponse }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(trimmedKey)")!
        let prompt = "Estimate the nutrition for this meal or snack: \(trimmedDescription). Return JSON only with exactly these keys: name (string), calories (integer kcal), carbs (integer grams), protein (integer grams), fats (integer grams). Use practical values and keep the answer realistic. No markdown or explanation."
        let requestBody = Request(contents: [.init(parts: [.init(text: prompt, inlineData: nil)])])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw GeminiNutritionError.requestFailed("Gemini took too long to respond. Please try again later.")
        } catch {
            throw GeminiNutritionError.requestFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GeminiNutritionError.requestFailed("Gemini could not estimate this meal. Please check your API key or try a clearer description.")
        }
        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decodedResponse.candidates?.first?.content.parts.first?.text else { throw GeminiNutritionError.invalidResponse }
        let cleanText = Self.jsonObjectText(from: text)
        let nutrition = try JSONDecoder().decode(Nutrition.self, from: Data(cleanText.utf8))
        return (nutrition.name ?? "Logged Meal", max(0, nutrition.calories), max(0, nutrition.carbs), max(0, nutrition.protein), max(0, nutrition.fats))
    }

    private static func jsonObjectText(from text: String) -> String {
        let withoutMarkdown = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = withoutMarkdown.firstIndex(of: "{"),
              let end = withoutMarkdown.lastIndex(of: "}") else {
            return withoutMarkdown
        }
        return String(withoutMarkdown[start...end])
    }

    func generateReportSummary(prompt: String, apiKey: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiNutritionError.invalidAPIKey }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(trimmedKey)")!
        let requestBody = Request(contents: [.init(parts: [.init(text: prompt, inlineData: nil)])])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GeminiNutritionError.requestFailed("Gemini could not create your report summary.")
        }
        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decodedResponse.candidates?.first?.content.parts.first?.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiNutritionError.invalidResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func motivationalQuote(apiKey: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiNutritionError.invalidAPIKey }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(trimmedKey)")!
        let prompt = "Write one short, original motivational sentence about healthy eating and consistent nutrition tracking. Return only the sentence, with no quotation marks, labels, markdown, or explanation."
        let requestBody = Request(contents: [.init(parts: [.init(text: prompt, inlineData: nil)])])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw GeminiNutritionError.requestFailed("Gemini took too long to respond. Please try again later.")
        } catch {
            throw GeminiNutritionError.requestFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw GeminiNutritionError.requestFailed("Gemini could not create a motivation message. Check your API key and try again.")
        }
        let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decodedResponse.candidates?.first?.content.parts.first?.text else { throw GeminiNutritionError.invalidResponse }
        let quote = text.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”"))
        guard !quote.isEmpty else { throw GeminiNutritionError.invalidResponse }
        return quote
    }
}
