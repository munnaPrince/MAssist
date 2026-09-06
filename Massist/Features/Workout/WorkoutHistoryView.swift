import SwiftUI
import Charts
import MapKit

struct WorkoutHistoryView: View {
    @EnvironmentObject private var historyStore: WorkoutHistoryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Workout history")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Review saved routes, distance, pace, steps, and calories.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if historyStore.records.isEmpty {
                    ContentUnavailableView("No workouts saved", systemImage: "figure.walk", description: Text("Finish a workout and tap Save workout to build your history."))
                } else {
                    ForEach(historyStore.records) { record in
                        WorkoutHistoryCard(record: record, imageURL: historyStore.snapshotURL(for: record))
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WorkoutHistoryCard: View {
    let record: WorkoutRecord
    let imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let imageURL, let image = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoutePreview(coordinates: record.routeLocations)
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            HStack {
                Label(record.workoutType.rawValue, systemImage: record.workoutType.icon)
                    .font(.headline)
                Spacer()
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                HistoryMetric(title: "Distance", value: String(format: "%.2f km", record.distanceMeters / 1000))
                HistoryMetric(title: "Duration", value: duration(record.duration))
                HistoryMetric(title: "Steps", value: "\(record.steps)")
                HistoryMetric(title: "Calories", value: String(format: "%.0f kcal", record.calories))
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}

private struct HistoryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WeeklyStepsChart: View {
    @EnvironmentObject private var historyStore: WorkoutHistoryStore
    @State private var weekOffset = 0
    let stepTarget: Int

    private var weekStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: weekOffset * 7, to: startOfWeek(today)) ?? today
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var chartData: [(date: Date, steps: Int)] {
        weekDays.map { day in
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
            let steps = historyStore.records
                .filter { $0.date >= day && $0.date < nextDay }
                .reduce(0) { $0 + $1.steps }
            return (day, steps)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Weekly steps").font(.headline)
                    Text(weekLabel).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Previous week")
                    Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }
                        .disabled(weekOffset >= 0)
                        .accessibilityLabel("Next week")
                }
                .buttonStyle(.bordered)
            }

            Chart(chartData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(5)
            }
            .chartYScale(domain: 0...max(stepTarget, max(chartData.map(\.steps).max() ?? 0, 1)))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 190)

            Text("Target: \(stepTarget) steps per day")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: end))"
    }

    private func startOfWeek(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
}

private struct RoutePreview: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Map {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.primaryOrange, lineWidth: 5)
            }
        }
        .mapStyle(.standard)
    }
}
