//
//  TripPlannerViewModel.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class TripPlannerViewModel {
    enum TripPlanState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum WeatherState: Equatable {
        case idle
        case loading
        case loaded
        case unavailable
    }

    private(set) var state: TripPlanState = .idle
    private(set) var weatherState: WeatherState = .idle
    private(set) var routePlan: RoutePlan?
    private(set) var origin: RouteWaypoint?
    private(set) var destination: RouteWaypoint?
    private(set) var stop: RouteWaypoint?
    private(set) var selectedRouteID: UUID?
    private(set) var departureDate: Date?

    private let directionsService: DirectionsService
    private let weatherService: WeatherService
    private var planTask: Task<Void, Never>?
    private var weatherTask: Task<Void, Never>?
    private let maxAlternatives = 3
    private let currentLocationName = "Current location"
    private let sampleSpacing: CLLocationDistance = 5000
    private let maxRainSamples = 60
    private let weatherChunkSize = 8

    init(directionsService: DirectionsService, weatherService: WeatherService) {
        self.directionsService = directionsService
        self.weatherService = weatherService
    }

    var isWeatherLoading: Bool {
        weatherState == .loading
    }

    var weatherUnavailable: Bool {
        weatherState == .unavailable
    }

    private var selectedAlternativeIndex: Int? {
        guard let selectedRouteID, let plan = routePlan else { return nil }
        return plan.alternatives.firstIndex(where: { $0.id == selectedRouteID })
    }

    func updateDestination(_ waypoint: RouteWaypoint) {
        destination = waypoint
        routePlan = nil
        selectedRouteID = nil
        plan()
    }

    func updateOrigin(_ waypoint: RouteWaypoint) {
        origin = waypoint
        plan()
    }

    func setOriginFromCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        updateOrigin(RouteWaypoint(
            name: currentLocationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }

    func addStop(_ waypoint: RouteWaypoint) {
        if let origin, let destination, !sameLocation(origin, destination) {
            guard !sameLocation(waypoint, origin), !sameLocation(waypoint, destination) else {
                state = .failed("Stop must be different from origin and destination.")
                return
            }
        }
        stop = waypoint
        plan()
    }

    func removeStop() {
        stop = nil
        plan()
    }

    func selectRoute(_ id: UUID) {
        selectedRouteID = id
        guard let plan = routePlan else { return }
        routePlan = RoutePlan(
            origin: plan.origin,
            destination: plan.destination,
            stop: plan.stop,
            alternatives: plan.alternatives,
            selectedRouteID: id
        )
        guard let selected = plan.alternatives.first(where: { $0.id == id }) else { return }
        if selected.rainSegments.isEmpty {
            loadWeather(for: selected, departure: departureDate)
        } else {
            weatherState = .loaded
        }
    }

    func setDepartureDate(_ date: Date?) {
        if let date {
            departureDate = max(date, Date())
        } else {
            departureDate = nil
        }
        plan()
    }

    func plan() {
        runRouting(loadWeather: false)
    }

    func checkRoute() {
        runRouting(loadWeather: true)
    }

    private func runRouting(loadWeather: Bool) {
        cancelPlan()
        weatherState = .idle
        guard let origin, let destination else { return }
        guard !sameLocation(origin, destination) else {
            state = .failed("Origin and destination must be different.")
            return
        }
        if let stop {
            guard !sameLocation(stop, destination), !sameLocation(stop, origin) else {
                state = .failed("Stop must be different from origin and destination.")
                return
            }
        }

        state = .loading
        let originValue = origin
        let destinationValue = destination
        let stopValue = stop
        let departureValue = departureDate
        let previousSelectedIndex = selectedAlternativeIndex
        planTask = Task { [weak self] in
            guard let self else { return }
            do {
                let alternatives = try await self.directionsService.route(
                    from: originValue,
                    to: destinationValue,
                    via: stopValue,
                    maxAlternatives: self.maxAlternatives,
                    departureDate: departureValue
                )
                guard !Task.isCancelled else { return }
                guard !alternatives.isEmpty else {
                    self.state = .failed("No routes found.")
                    return
                }
                self.applyRoute(
                    alternatives: alternatives,
                    origin: originValue,
                    destination: destinationValue,
                    stop: stopValue,
                    selectedIndex: previousSelectedIndex
                )
                self.state = .loaded
                if loadWeather, let selected = self.routePlan?.alternatives.first(where: { $0.id == self.selectedRouteID }) {
                    self.loadWeather(for: selected, departure: departureValue)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    func clear() {
        cancelPlan()
        origin = nil
        destination = nil
        stop = nil
        selectedRouteID = nil
        departureDate = nil
        routePlan = nil
        state = .idle
        weatherState = .idle
    }

    private func loadWeather(for alternative: RouteAlternative, departure: Date?) {
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            guard let self else { return }
            self.weatherState = .loading
            do {
                let segments = try await self.sampleRain(for: alternative, departure: departure)
                guard !Task.isCancelled else { return }
                guard let plan = self.routePlan else { return }
                self.routePlan = RoutePlan(
                    origin: plan.origin,
                    destination: plan.destination,
                    stop: plan.stop,
                    alternatives: plan.alternatives.map { alt in
                        guard alt.id == alternative.id else { return alt }
                        return RouteAlternative(
                            id: alt.id,
                            distance: alt.distance,
                            travelTime: alt.travelTime,
                            polyline: alt.polyline,
                            coordinatePoints: alt.coordinatePoints,
                            rainSegments: segments
                        )
                    },
                    selectedRouteID: plan.selectedRouteID
                )
                self.weatherState = .loaded
            } catch {
                guard !Task.isCancelled else { return }
                self.weatherState = .unavailable
            }
        }
    }

    private func sampleRain(for alternative: RouteAlternative, departure: Date?) async throws -> [RainSegment] {
        let samples = samplePoints(alternative.coordinatePoints)
        guard !samples.isEmpty else { return [] }
        let departureValue = departure ?? Date()
        let totalDistance = max(alternative.distance, samples.last?.distanceFromStart ?? 0)
        var segments: [RainSegment] = []
        var offset = 0
        while offset < samples.count {
            let end = min(offset + weatherChunkSize, samples.count)
            let chunk = samples[offset..<end]
            let batch = try await withThrowingTaskGroup(of: (Int, RainSegment).self) { group in
                for sample in chunk {
                    group.addTask {
                        let fraction = totalDistance > 0 ? sample.distanceFromStart / totalDistance : 0
                        let arrival = departureValue.addingTimeInterval(fraction * alternative.travelTime)
                        let chance = try await self.weatherService.rainChance(at: sample.coordinate, on: arrival)
                        return (
                            sample.index,
                            RainSegment(
                                index: sample.index,
                                coordinate: sample.coordinate,
                                distanceFromStart: sample.distanceFromStart,
                                rainChance: chance
                            )
                        )
                    }
                }
                var collected: [(Int, RainSegment)] = []
                for try await entry in group {
                    collected.append(entry)
                }
                return collected
            }
            segments.append(contentsOf: batch.map(\.1))
            offset = end
        }
        return segments.sorted { $0.index < $1.index }
    }

    private func samplePoints(_ points: [CLLocationCoordinate2D]) -> [RainSample] {
        guard let first = points.first else { return [] }
        var samples = [RainSample(coordinate: first, distanceFromStart: 0, index: 0)]
        var accumulated: CLLocationDistance = 0
        var nextThreshold = sampleSpacing
        var previous = first
        for point in points.dropFirst() {
            accumulated += distance(from: previous, to: point)
            if accumulated >= nextThreshold, samples.count < maxRainSamples {
                samples.append(RainSample(coordinate: point, distanceFromStart: accumulated, index: samples.count))
                nextThreshold += sampleSpacing
            }
            previous = point
        }
        return samples
    }

    private struct RainSample {
        let coordinate: CLLocationCoordinate2D
        let distanceFromStart: CLLocationDistance
        let index: Int
    }

    private func applyRoute(
        alternatives: [RouteAlternative],
        origin: RouteWaypoint,
        destination: RouteWaypoint,
        stop: RouteWaypoint?,
        selectedIndex: Int?
    ) {
        let selected: UUID?
        if let selectedIndex, alternatives.indices.contains(selectedIndex) {
            selected = alternatives[selectedIndex].id
        } else {
            selected = alternatives.first?.id
        }
        self.origin = origin
        self.destination = destination
        self.stop = stop
        self.selectedRouteID = selected
        routePlan = RoutePlan(
            origin: origin,
            destination: destination,
            stop: stop,
            alternatives: alternatives,
            selectedRouteID: selected
        )
    }

    private func sameLocation(_ a: RouteWaypoint, _ b: RouteWaypoint) -> Bool {
        a.latitude == b.latitude && a.longitude == b.longitude
    }

    private func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private func cancelPlan() {
        planTask?.cancel()
        planTask = nil
        weatherTask?.cancel()
        weatherTask = nil
    }
}