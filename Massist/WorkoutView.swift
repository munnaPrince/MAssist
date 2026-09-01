import SwiftUI
import CoreLocation

struct WorkoutView: View {

    @StateObject private var tracker = WorkoutTracker()

    @State private var selectedWorkout: WorkoutType = .walking

    @State private var showingPermissionAlert = false

    @State private var showingFinishConfirmation = false

    @State private var showingSummary = false

    // Change this later to your user's actual profile weight.
    @State private var userWeightKg: Double = 70

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    workoutTypeSelector

                    mapSection

                    statisticsSection

                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Location Permission Required",
                isPresented: $showingPermissionAlert
            ) {

                Button("Open Settings") {

                    if let url = URL(
                        string: UIApplication.openSettingsURLString
                    ) {

                        UIApplication.shared.open(url)
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {

                Text(
                    "MAssist needs your location to track your walking, jogging, or running route."
                )
            }
            .confirmationDialog(
                "Finish Workout?",
                isPresented: $showingFinishConfirmation,
                titleVisibility: .visible
            ) {

                Button("Finish Workout") {

                    tracker.finishWorkout()

                    showingSummary = true
                }

                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingSummary) {

                WorkoutSummaryView(
                    tracker: tracker,
                    weightKg: userWeightKg
                )
            }
        }
        .onAppear {

            tracker.requestLocationPermission()
        }
    }

    // MARK: - Workout Type

    private var workoutTypeSelector: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Workout")

                .font(.title3.weight(.bold))

            HStack(spacing: 10) {

                ForEach(WorkoutType.allCases) { type in

                    Button {

                        guard !tracker.isTracking else {
                            return
                        }

                        selectedWorkout = type

                    } label: {

                        VStack(spacing: 8) {

                            Image(systemName: type.icon)

                                .font(.title2)

                            Text(type.rawValue)

                                .font(
                                    .caption.weight(.semibold)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(
                            selectedWorkout == type
                            ? .white
                            : .primary
                        )
                        .background(
                            selectedWorkout == type
                            ? Color.primaryOrange
                            : Color.secondary.opacity(0.12)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                    }
                    .disabled(tracker.isTracking)
                }
            }
        }
    }

    // MARK: - Map

    private var mapSection: some View {

        ZStack(alignment: .topTrailing) {

            WorkoutMapView(
                tracker: tracker
            )
            .frame(height: 350)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )

            if tracker.isTracking {

                Text(
                    tracker.isPaused
                    ? "PAUSED"
                    : "LIVE"
                )
                .font(
                    .caption.weight(.bold)
                )
                .padding(
                    .horizontal,
                    10
                )
                .padding(
                    .vertical,
                    6
                )
                .background(
                    .ultraThinMaterial
                )
                .clipShape(
                    Capsule()
                )
                .padding(12)
            }
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {

        VStack(spacing: 14) {

            HStack(spacing: 12) {

                StatCard(
                    title: "Distance",
                    value: formattedDistance,
                    systemImage: "figure.walk"
                )

                StatCard(
                    title: "Duration",
                    value: formattedDuration,
                    systemImage: "timer"
                )
            }

            HStack(spacing: 12) {

                StatCard(
                    title: "Current Speed",
                    value: formattedSpeed,
                    systemImage: "speedometer"
                )

                StatCard(
                    title: "Pace",
                    value: formattedPace,
                    systemImage: "gauge.with.dots.needle.33percent"
                )
            }

            HStack(spacing: 12) {

                StatCard(
                    title: "Steps",
                    value: "\(tracker.stepCount)",
                    systemImage: "shoeprints.fill"
                )

                StatCard(
                    title: "Calories",
                    value: String(format: "%.0f kcal", tracker.estimatedCalories(weightKg: 70)),
                    systemImage: "flame.fill"
                )
            }
        }
    }

    // MARK: - Buttons

    private var actionButtons: some View {

        VStack(spacing: 12) {

            if !tracker.isTracking {

                Button {

                    startWorkout()

                } label: {

                    Label(
                        "Start \(selectedWorkout.rawValue)",
                        systemImage: "play.fill"
                    )
                    .font(
                        .headline.weight(.semibold)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primaryOrange)
            }

            else {

                HStack(spacing: 12) {

                    Button {

                        if tracker.isPaused {
                            tracker.resumeWorkout()
                        } else {
                            tracker.pauseWorkout()
                        }

                    } label: {

                        Label(
                            tracker.isPaused
                            ? "Resume"
                            : "Pause",
                            systemImage:
                                tracker.isPaused
                                ? "play.fill"
                                : "pause.fill"
                        )
                        .font(
                            .headline.weight(.semibold)
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)

                    Button {

                        showingFinishConfirmation = true

                    } label: {

                        Label(
                            "Finish",
                            systemImage: "stop.fill"
                        )
                        .font(
                            .headline.weight(.semibold)
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
    }

    // MARK: - Start

    private func startWorkout() {

        let status =
            tracker.authorizationStatus

        guard status == .authorizedWhenInUse ||
              status == .authorizedAlways else {

            showingPermissionAlert = true

            return
        }

        tracker.startWorkout(
            type: selectedWorkout
        )
    }

    // MARK: - Formatting

    private var formattedDistance: String {

        String(
            format: "%.2f km",
            tracker.distanceMeters / 1000
        )
    }

    private var formattedDuration: String {

        let totalSeconds =
            Int(tracker.elapsedTime)

        let hours =
            totalSeconds / 3600

        let minutes =
            (totalSeconds % 3600) / 60

        let seconds =
            totalSeconds % 60

        if hours > 0 {

            return String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                seconds
            )

        } else {

            return String(
                format: "%02d:%02d",
                minutes,
                seconds
            )
        }
    }

    private var formattedSpeed: String {

        String(
            format: "%.1f km/h",
            tracker.currentSpeed * 3.6
        )
    }

    private var formattedPace: String {

        guard let pace =
                tracker.paceSecondsPerKilometer else {

            return "--"
        }

        let minutes =
            Int(pace) / 60

        let seconds =
            Int(pace) % 60

        return String(
            format: "%d:%02d /km",
            minutes,
            seconds
        )
    }
}
struct WorkoutSummaryView: View {

    @ObservedObject var tracker: WorkoutTracker

    let weightKg: Double

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    Image(
                        systemName:
                            tracker.workoutType?.icon
                            ?? "figure.walk"
                    )
                    .font(.system(size: 60))
                    .foregroundStyle(
                        Color.primaryOrange
                    )

                    Text(
                        tracker.workoutType?.rawValue
                        ?? "Workout"
                    )
                    .font(.title.bold())

                    Text("Workout Complete")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {

                        SummaryRow(
                            title: "Distance",
                            value: String(
                                format: "%.2f km",
                                tracker.distanceMeters / 1000
                            )
                        )

                        SummaryRow(
                            title: "Duration",
                            value: formattedDuration
                        )

                        SummaryRow(
                            title: "Average Pace",
                            value: formattedPace
                        )

                        SummaryRow(
                            title: "Average Speed",
                            value: String(
                                format: "%.1f km/h",
                                tracker.averageSpeed * 3.6
                            )
                        )

                        SummaryRow(
                            title: "Steps",
                            value: "\(tracker.stepCount)"
                        )

                        SummaryRow(
                            title: "Estimated Calories",
                            value: String(
                                format: "%.0f kcal",
                                tracker.estimatedCalories(
                                    weightKg: weightKg
                                )
                            )
                        )
                    }
                    .padding()
                    .background(
                        Color.secondary.opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )

                    Button("Done") {

                        tracker.reset()

                        dismiss()

                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                    .tint(
                        .primaryOrange
                    )
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var formattedDuration: String {

        let totalSeconds =
            Int(tracker.elapsedTime)

        let hours =
            totalSeconds / 3600

        let minutes =
            (totalSeconds % 3600) / 60

        let seconds =
            totalSeconds % 60

        if hours > 0 {

            return String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                seconds
            )

        } else {

            return String(
                format: "%02d:%02d",
                minutes,
                seconds
            )
        }
    }

    private var formattedPace: String {

        guard let pace =
                tracker.paceSecondsPerKilometer else {

            return "--"
        }

        let minutes =
            Int(pace) / 60

        let seconds =
            Int(pace) % 60

        return String(
            format: "%d:%02d /km",
            minutes,
            seconds
        )
    }
}
struct SummaryRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.body.weight(.semibold))
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.primaryOrange)

            Text(value)
                .font(.title3.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}