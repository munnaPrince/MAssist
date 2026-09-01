import Foundation
import CoreLocation
import CoreMotion
import Combine

@MainActor
final class WorkoutTracker: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    @Published private(set) var route: [CLLocation] = []

    @Published private(set) var distanceMeters: Double = 0

    @Published private(set) var elapsedTime: TimeInterval = 0

    @Published private(set) var currentSpeed: Double = 0

    @Published private(set) var averageSpeed: Double = 0

    @Published private(set) var stepCount: Int = 0

    @Published private(set) var isTracking = false

    @Published private(set) var isPaused = false

    @Published private(set) var workoutType: WorkoutType?

    @Published private(set) var startDate: Date?

    @Published private(set) var endDate: Date?

    // MARK: - Private

    private let locationManager = CLLocationManager()

    private let pedometer = CMPedometer()

    private var timer: Timer?

    private var lastLocation: CLLocation?

    private var accumulatedTime: TimeInterval = 0

    private var activeStartDate: Date?

    // MARK: - Init

    override init() {
        super.init()

        locationManager.delegate = self

        locationManager.activityType = .fitness

        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.distanceFilter = 5

        locationManager.allowsBackgroundLocationUpdates = true

        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Start

    func startWorkout(type: WorkoutType) {

        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {

            requestLocationPermission()
            return
        }

        workoutType = type

        route.removeAll()

        distanceMeters = 0

        elapsedTime = 0

        stepCount = 0

        accumulatedTime = 0

        lastLocation = nil

        isTracking = true

        isPaused = false

        startDate = Date()

        endDate = nil

        activeStartDate = Date()

        startStepTrackingIfAvailable()

        locationManager.startUpdatingLocation()

        startTimer()
    }

    // MARK: - Pause

    func pauseWorkout() {

        guard isTracking, !isPaused else {
            return
        }

        if let activeStartDate {
            accumulatedTime += Date().timeIntervalSince(activeStartDate)
        }

        self.activeStartDate = nil

        isPaused = true

        stopStepTracking()

        locationManager.stopUpdatingLocation()

        stopTimer()

        updateElapsedTime()
    }

    // MARK: - Resume

    func resumeWorkout() {

        guard isTracking, isPaused else {
            return
        }

        activeStartDate = Date()

        isPaused = false

        startStepTrackingIfAvailable()

        locationManager.startUpdatingLocation()

        startTimer()
    }

    // MARK: - Finish

    func finishWorkout() {

        guard isTracking else {
            return
        }

        if let activeStartDate {
            accumulatedTime += Date().timeIntervalSince(activeStartDate)
        }

        endDate = Date()

        updateElapsedTime()

        isTracking = false

        isPaused = false

        activeStartDate = nil

        stopStepTracking()

        locationManager.stopUpdatingLocation()

        stopTimer()

        calculateAverageSpeed()
    }

    // MARK: - Timer

    private func startTimer() {

        stopTimer()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in

            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    private func stopTimer() {

        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {

        guard isTracking else {
            return
        }

        if let activeStartDate {

            elapsedTime =
                accumulatedTime +
                Date().timeIntervalSince(activeStartDate)
        } else {

            elapsedTime = accumulatedTime
        }

        calculateAverageSpeed()
    }

    // MARK: - Step Tracking

    private func startStepTrackingIfAvailable() {
        guard CMPedometer.isStepCountingAvailable() else {
            stepCount = Int(distanceMeters / 0.75)
            return
        }

        pedometer.startUpdates(from: Date()) { [weak self] data, _ in
            guard let self, let data else { return }

            let steps = Int(truncating: data.numberOfSteps)
            Task { @MainActor in
                self.stepCount = max(self.stepCount, steps)
            }
        }
    }

    private func stopStepTracking() {
        pedometer.stopUpdates()
    }

    // MARK: - Distance

    private func processLocation(_ location: CLLocation) {

        guard isTracking, !isPaused else {
            return
        }

        guard location.horizontalAccuracy >= 0 else {
            return
        }

        guard location.horizontalAccuracy <= 50 else {
            return
        }

        if let previous = lastLocation {

            let distance = location.distance(from: previous)

            // Ignore unrealistic GPS jumps.
            guard distance < 100 else {
                return
            }

            if distance > 1 {
                distanceMeters += distance
                if !CMPedometer.isStepCountingAvailable() {
                    stepCount = Int(distanceMeters / 0.75)
                }
            }
        }

        lastLocation = location

        route.append(location)

        currentSpeed =
            max(location.speed, 0)

        calculateAverageSpeed()
    }

    private func calculateAverageSpeed() {

        guard elapsedTime > 0 else {
            averageSpeed = 0
            return
        }

        averageSpeed =
            distanceMeters / elapsedTime
    }

    // MARK: - Pace

    var paceSecondsPerKilometer: Double? {

        guard distanceMeters >= 10 else {
            return nil
        }

        let kilometers = distanceMeters / 1000

        guard kilometers > 0 else {
            return nil
        }

        return elapsedTime / kilometers
    }

    // MARK: - Calories

    func estimatedCalories(weightKg: Double) -> Double {

        guard elapsedTime > 0 else {
            return 0
        }

        let hours = elapsedTime / 3600

        let speedKmh =
            averageSpeed * 3.6

        let met: Double

        switch workoutType {

        case .walking:

            met = speedKmh < 4.8 ? 3.5 : 4.3

        case .jogging:

            met = 7.0

        case .running:

            if speedKmh < 8 {
                met = 8.0
            } else if speedKmh < 10 {
                met = 9.8
            } else {
                met = 11.0
            }

        case nil:

            met = 1
        }

        return met * weightKg * hours
    }

    // MARK: - Reset

    func reset() {

        stopTimer()

        locationManager.stopUpdatingLocation()

        route.removeAll()

        distanceMeters = 0

        elapsedTime = 0

        currentSpeed = 0

        averageSpeed = 0

        stepCount = 0

        isTracking = false

        isPaused = false

        workoutType = nil

        startDate = nil

        endDate = nil

        lastLocation = nil

        accumulatedTime = 0

        activeStartDate = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension WorkoutTracker: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else {
            return
        }

        Task { @MainActor [weak self] in
            self?.processLocation(location)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print("Location error:", error.localizedDescription)
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        let status = manager.authorizationStatus

        Task { @MainActor [weak self] in
            self?.authorizationStatus = status
        }
    }
}