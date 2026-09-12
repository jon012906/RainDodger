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
    private(set) var weatherAnalysis: RouteWeatherAnalyzer.AnalyzedRoute?
    private(set) var origin: RouteWaypoint?
    private(set) var destination: RouteWaypoint?
    private(set) var stop: RouteWaypoint?
    private(set) var selectedRouteID: UUID?
    private(set) var departureDate: Date?

    private let directionsService: DirectionsService
    private let weatherService: WeatherService
    private let weatherCache = WeatherCache()
    private let sampler = AdaptiveRouteSampler()
    private var planTask: Task<Void, Never>?
    private var weatherTask: Task<Void, Never>?
    private let maxAlternatives = 3
    private let currentLocationName = "Current location"
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

    var isOriginCurrentLocation: Bool {
        origin?.name == currentLocationName
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
        weatherState = selected.rainSegments.isEmpty ? .idle : .loaded
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
        weatherAnalysis = nil
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

    func clearDestination() {
        cancelPlan()
        destination = nil
        selectedRouteID = nil
        routePlan = nil
        weatherAnalysis = nil
        state = .idle
        weatherState = .idle
    }

    private func loadWeather(for alternative: RouteAlternative, departure: Date?) {
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            guard let self else { return }
            self.weatherState = .loading
            do {
                let forecastPoints = try await self.sampleForecast(for: alternative, departure: departure)
                guard !Task.isCancelled else { return }
                guard let plan = self.routePlan else { return }
                let segments = self.buildRainSegments(from: forecastPoints)
                let analysis = RouteWeatherAnalyzer.analyze(
                    forecastPoints: forecastPoints,
                    steps: alternative.steps,
                    totalDistance: alternative.distance,
                    departure: departure
                )
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
                            rainSegments: segments,
                            steps: RainMetrics.mappedSteps(
                                alt.steps,
                                rainSegments: segments,
                                totalDistance: alt.distance
                            )
                        )
                    },
                    selectedRouteID: plan.selectedRouteID
                )
                self.weatherAnalysis = analysis
                self.weatherState = .loaded
            } catch {
                guard !Task.isCancelled else { return }
                self.weatherState = .unavailable
            }
        }
    }

    private func sampleForecast(for alternative: RouteAlternative, departure: Date?) async throws -> [WeatherForecastPoint] {
        let initialSamples = sampler.initialSamples(from: alternative.coordinatePoints)
        guard !initialSamples.isEmpty else { return [] }
        let departureValue = departure ?? Date()
        let totalDistance = max(alternative.distance, initialSamples.last?.distanceFromStart ?? 0)
        var points: [WeatherForecastPoint] = []
        var offset = 0
        while offset < initialSamples.count {
            let end = min(offset + weatherChunkSize, initialSamples.count)
            let chunk = initialSamples[offset..<end]
            let batch = try await withThrowingTaskGroup(of: WeatherForecastPoint.self) { group in
                for sample in chunk {
                    group.addTask {
                        let fraction = totalDistance > 0 ? sample.distanceFromStart / totalDistance : 0
                        let arrival = departureValue.addingTimeInterval(fraction * alternative.travelTime)
                        return try await self.weatherCache.forecast(
                            at: sample.coordinate,
                            arrivalTime: arrival
                        ) {
                            try await self.weatherService.weatherForecast(at: sample.coordinate, on: arrival)
                        }
                    }
                }
                var collected: [WeatherForecastPoint] = []
                for try await entry in group {
                    collected.append(entry)
                }
                return collected
            }
            points.append(contentsOf: batch)
            offset = end
        }
        let sorted = points.sorted { $0.distanceFromStart < $1.distanceFromStart }
        let densified = sampler.densify(samples: initialSamples, forecasts: sorted, along: alternative.coordinatePoints)
        if densified.count > sorted.count {
            var extraPoints: [WeatherForecastPoint] = []
            let newSamples = densified.filter { s in !sorted.contains(where: { $0.distanceFromStart == s.distanceFromStart }) }
            for sample in newSamples {
                let fraction = totalDistance > 0 ? sample.distanceFromStart / totalDistance : 0
                let arrival = departureValue.addingTimeInterval(fraction * alternative.travelTime)
                let forecast = try await self.weatherCache.forecast(
                    at: sample.coordinate,
                    arrivalTime: arrival
                ) {
                    try await self.weatherService.weatherForecast(at: sample.coordinate, on: arrival)
                }
                extraPoints.append(forecast)
            }
            return (sorted + extraPoints).sorted { $0.distanceFromStart < $1.distanceFromStart }
        }
        return sorted
    }

    private func buildRainSegments(from forecastPoints: [WeatherForecastPoint]) -> [RainSegment] {
        forecastPoints.enumerated().map { index, point in
            RainSegment(
                index: index,
                coordinate: point.coordinate,
                distanceFromStart: point.distanceFromStart,
                arrivalDate: point.arrivalTime,
                rainChance: point.precipitationChance
            )
        }
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