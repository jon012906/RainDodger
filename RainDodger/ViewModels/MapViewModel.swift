//
//  MapViewModel.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import Foundation
import CoreLocation
import Observation

enum AuthorizationState: Equatable {
    case unknown
    case requesting
    case authorized
    case denied
}

enum CameraIntent: Equatable {
    case recenter
    case resetNorthAndRecenter
    case focusDestination(CLLocationCoordinate2D)

    static func == (lhs: CameraIntent, rhs: CameraIntent) -> Bool {
        switch (lhs, rhs) {
        case (.recenter, .recenter), (.resetNorthAndRecenter, .resetNorthAndRecenter):
            return true
        case let (.focusDestination(a), .focusDestination(b)):
            return a.latitude == b.latitude && a.longitude == b.longitude
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class MapViewModel {
    private let locationService: LocationService

    private(set) var authorizationState: AuthorizationState = .unknown
    private(set) var cameraIntent: CameraIntent?
    private(set) var heading: CLLocationDirection?
    private(set) var locationErrorMessage: String?
    private(set) var selectedDestination: SearchResult?
    private(set) var currentCoordinate: CLLocationCoordinate2D?
    var isSearchPresented = false
    var isTripSheetPresented = false

    private var locationTask: Task<Void, Never>?
    private var headingTask: Task<Void, Never>?
    private var smoothedHeading: CLLocationDirection?
    private let headingSmoothingFactor = 0.2

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func onAppear() {
        refreshAuthorizationState()
    }

    func refreshAuthorizationState() {
        guard authorizationState != .requesting else { return }
        Task { await syncAuthorizationState() }
    }

    func onDisappear() {
        locationTask?.cancel()
        locationTask = nil
        headingTask?.cancel()
        headingTask = nil
    }

    func recenter() {
        cameraIntent = .recenter
    }

    func resetNorthAndRecenter() {
        cameraIntent = .resetNorthAndRecenter
    }

    func consumeCameraIntent() {
        cameraIntent = nil
    }

    func retryLocation() {
        locationErrorMessage = nil
        locationTask?.cancel()
        locationTask = nil
        startLocationAndHeading()
    }

    func searchFieldTapped() {
        isSearchPresented = true
    }

    func selectDestination(_ result: SearchResult) {
        selectedDestination = result
        cameraIntent = .focusDestination(result.coordinate)
        isSearchPresented = false
        isTripSheetPresented = true
    }

    private func syncAuthorizationState() async {
        var status = await locationService.authorizationStatus()
        if status == .notDetermined {
            authorizationState = .requesting
            status = await locationService.requestWhenInUseAuthorization()
        }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationState = .authorized
            startLocationAndHeading()
        default:
            authorizationState = .denied
            stopLocationAndHeading()
            locationErrorMessage = nil
        }
    }

    private func startLocationAndHeading() {
        if locationTask == nil {
            locationErrorMessage = nil
            locationTask = Task { [weak self] in
                await self?.fetchCurrentLocation()
            }
        }
        if headingTask == nil {
            headingTask = Task { [weak self] in
                await self?.consumeHeadingUpdates()
            }
        }
    }

    private func stopLocationAndHeading() {
        locationTask?.cancel()
        locationTask = nil
        headingTask?.cancel()
        headingTask = nil
    }

    private func fetchCurrentLocation() async {
        do {
            let location = try await locationService.currentLocation()
            guard !Task.isCancelled else { return }
            currentCoordinate = location.coordinate
            locationErrorMessage = nil
        } catch let error as LocationError {
            guard !Task.isCancelled else { return }
            locationErrorMessage = error.localizedDescription
        } catch {
            guard !Task.isCancelled else { return }
            locationErrorMessage = LocationError.locationUnavailable.localizedDescription
        }
    }

    private func consumeHeadingUpdates() async {
        let stream = locationService.headingUpdates()
        for await sample in stream {
            guard let acceptedHeading = acceptHeadingSample(sample) else { continue }
            heading = acceptedHeading
        }
    }

    private func acceptHeadingSample(_ value: CLLocationDirection) -> CLLocationDirection? {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        guard let current = smoothedHeading else {
            smoothedHeading = normalized
            return normalized
        }
        let difference = (normalized - current + 540).truncatingRemainder(dividingBy: 360) - 180
        guard abs(difference) < 180 else { return nil }
        smoothedHeading = (current + difference * headingSmoothingFactor + 360).truncatingRemainder(dividingBy: 360)
        return smoothedHeading
    }
}
