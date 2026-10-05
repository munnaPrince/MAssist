import Foundation
import MapKit
import UIKit
import Combine

struct WorkoutRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let workoutType: WorkoutType
    let distanceMeters: Double
    let duration: TimeInterval
    let averageSpeed: Double
    let steps: Int
    let calories: Double
    let route: [WorkoutCoordinate]
    let mapSnapshotFilename: String?

    var routeLocations: [CLLocationCoordinate2D] {
        route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

struct WorkoutCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}

@MainActor
final class WorkoutHistoryStore: ObservableObject {
    @Published private(set) var records: [WorkoutRecord] = []

    private let filename = "massist-workouts.csv"

    init() {
        records = loadRecords()
    }

    func saveWorkout(
        tracker: WorkoutTracker,
        weightKg: Double
    ) async {
        let recordID = UUID()
        let snapshotFilename = await saveMapSnapshot(
            route: tracker.route,
            recordID: recordID
        )
        let record = WorkoutRecord(
            id: recordID,
            date: tracker.startDate ?? Date(),
            workoutType: tracker.workoutType ?? .walking,
            distanceMeters: tracker.distanceMeters,
            duration: tracker.elapsedTime,
            averageSpeed: tracker.averageSpeed,
            steps: tracker.stepCount,
            calories: tracker.estimatedCalories(weightKg: weightKg),
            route: tracker.route.map { WorkoutCoordinate($0.coordinate) },
            mapSnapshotFilename: snapshotFilename
        )
        records.insert(record, at: 0)
        writeRecords()
    }

    func snapshotURL(for record: WorkoutRecord) -> URL? {
        guard let filename = record.mapSnapshotFilename else { return nil }
        return documentsDirectory.appendingPathComponent(filename)
    }

    private func saveMapSnapshot(
        route: [CLLocation],
        recordID: UUID
    ) async -> String? {
        guard !route.isEmpty else { return nil }
        let coordinates = route.map(\.coordinate)
        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        let paddedRect = rect.insetBy(dx: -max(rect.size.width * 0.2, 1_000), dy: -max(rect.size.height * 0.2, 1_000))
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(paddedRect)
        options.size = CGSize(width: 900, height: 600)
        options.scale = UIScreen.main.scale
        options.mapType = .standard
        let configuredSnapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await configuredSnapshotter.start()
            guard let data = snapshot.image.pngData() else { return nil }
            let filename = "workout-map-\(recordID.uuidString).png"
            try data.write(to: documentsDirectory.appendingPathComponent(filename), options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    private func loadRecords() -> [WorkoutRecord] {
        guard let data = try? Data(contentsOf: csvURL),
              let contents = String(data: data, encoding: .utf8) else { return [] }
        return contents
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .compactMap { WorkoutCSVCodec.decode(String($0)) }
            .sorted { $0.date > $1.date }
    }

    private func writeRecords() {
        let csv = WorkoutCSVCodec.header + records.map(WorkoutCSVCodec.encode).joined(separator: "\n") + "\n"
        try? Data(csv.utf8).write(to: csvURL, options: .atomic)
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var csvURL: URL {
        documentsDirectory.appendingPathComponent(filename)
    }
}

enum WorkoutCSVCodec {
    static let header = "ID,Date,Workout,Distance (m),Duration (s),Average Speed (m/s),Steps,Calories,Route,Map Snapshot\n"

    static func encode(_ record: WorkoutRecord) -> String {
        let routeData = try? JSONEncoder().encode(record.route)
        let route = routeData?.base64EncodedString() ?? ""
        return [
            record.id.uuidString,
            ISO8601DateFormatter().string(from: record.date),
            record.workoutType.rawValue,
            String(record.distanceMeters),
            String(record.duration),
            String(record.averageSpeed),
            String(record.steps),
            String(record.calories),
            route,
            record.mapSnapshotFilename ?? ""
        ].map(escape).joined(separator: ",")
    }

    static func decode(_ line: String) -> WorkoutRecord? {
        let values = parse(line)
        guard values.count >= 10,
              let id = UUID(uuidString: values[0]),
              let date = ISO8601DateFormatter().date(from: values[1]),
              let workoutType = WorkoutType(rawValue: values[2]),
              let distance = Double(values[3]),
              let duration = Double(values[4]),
              let speed = Double(values[5]),
              let steps = Int(values[6]),
              let calories = Double(values[7]),
              let route = decodeRoute(values[8]) else { return nil }
        return WorkoutRecord(id: id, date: date, workoutType: workoutType, distanceMeters: distance, duration: duration, averageSpeed: speed, steps: steps, calories: calories, route: route, mapSnapshotFilename: values[9].isEmpty ? nil : values[9])
    }

    private static func decodeRoute(_ value: String) -> [WorkoutCoordinate]? {
        guard !value.isEmpty else { return [] }
        guard let data = Data(base64Encoded: value) else { return nil }
        return try? JSONDecoder().decode([WorkoutCoordinate].self, from: data)
    }

    nonisolated private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func parse(_ line: String) -> [String] {
        var result: [String] = []
        var value = ""
        var quoted = false
        var iterator = line.makeIterator()
        while let character = iterator.next() {
            if character == "\"" { quoted.toggle() }
            else if character == "," && !quoted { result.append(value); value = "" }
            else { value.append(character) }
        }
        result.append(value)
        return result.map { $0.replacingOccurrences(of: "\"\"", with: "\"") }
    }
}
