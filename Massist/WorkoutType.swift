import Foundation

enum WorkoutType: String, CaseIterable, Identifiable, Codable {
    case walking = "Walking"
    case jogging = "Jogging"
    case running = "Running"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .jogging:
            return "figure.jogging"
        case .running:
            return "figure.run"
        }
    }

    var colorName: String {
        switch self {
        case .walking:
            return "Walking"
        case .jogging:
            return "Jogging"
        case .running:
            return "Running"
        }
    }
}