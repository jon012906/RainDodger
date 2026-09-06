//
//  LocationService.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import Foundation
import CoreLocation

enum LocationError: LocalizedError {
    case authorizationDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location access is turned off. Enable it in Settings to see your position on the map."
        case .locationUnavailable:
            return "Your position is not available right now. Try again when you have a clear sky view."
        }
    }
}

protocol LocationService: AnyObject {
    func authorizationStatus() async -> CLAuthorizationStatus
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus
    func currentLocation() async throws -> CLLocation
    func headingUpdates() -> AsyncStream<CLLocationDirection>
}

@MainActor
final class LiveLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var locationTimeoutTask: Task<Void, Never>?
    private var headingContinuation: AsyncStream<CLLocationDirection>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.headingFilter = 2
        manager.headingOrientation = .portrait
        manager.activityType = .automotiveNavigation
    }

    func authorizationStatus() async -> CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let currentStatus = manager.authorizationStatus
        guard currentStatus == .notDetermined else { return currentStatus }
        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func currentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.authorizationDenied
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                self?.reportLocationTimeout()
            }
            manager.startUpdatingLocation()
        }
    }

    func headingUpdates() -> AsyncStream<CLLocationDirection> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            headingContinuation = continuation
            manager.startUpdatingHeading()
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopHeadingUpdates()
                }
            }
        }
    }

    private func reportLocationTimeout() {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        locationTimeoutTask = nil
        manager.stopUpdatingLocation()
        continuation.resume(throwing: LocationError.locationUnavailable)
    }

    private func finishLocationFetch(with result: Result<CLLocation, Error>) {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
        manager.stopUpdatingLocation()
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }

    private func stopHeadingUpdates() {
        headingContinuation?.finish()
        headingContinuation = nil
        manager.stopUpdatingHeading()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            let status = self.manager.authorizationStatus
            self.authorizationContinuation?.resume(returning: status)
            self.authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated { [weak self] in
            guard let self, let location = locations.last else { return }
            guard location.horizontalAccuracy >= 0 else { return }
            self.finishLocationFetch(with: .success(location))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            self.finishLocationFetch(with: .failure(LocationError.locationUnavailable))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            guard value >= 0 else { return }
            self.headingContinuation?.yield(value)
        }
    }
}

@MainActor
final class MockLocationService: LocationService {
    var authorizationState: CLAuthorizationStatus
    var coordinate = CLLocationCoordinate2D(latitude: 52.2592, longitude: 20.9916)
    private let headingSequence: [CLLocationDirection] = [0, 45, 90, 180]

    init(authorizationState: CLAuthorizationStatus = .authorizedWhenInUse) {
        self.authorizationState = authorizationState
    }

    func authorizationStatus() async -> CLAuthorizationStatus {
        authorizationState
    }

    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        authorizationState = .authorizedWhenInUse
        return authorizationState
    }

    func currentLocation() async throws -> CLLocation {
        guard authorizationState == .authorizedWhenInUse || authorizationState == .authorizedAlways else {
            throw LocationError.authorizationDenied
        }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    func headingUpdates() -> AsyncStream<CLLocationDirection> {
        AsyncStream { continuation in
            let generator = Task { @MainActor in
                var index = 0
                while !Task.isCancelled {
                    continuation.yield(self.headingSequence[index % self.headingSequence.count])
                    index += 1
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            continuation.onTermination = { @Sendable _ in
                generator.cancel()
            }
        }
    }
}
