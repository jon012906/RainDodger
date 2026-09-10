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

    private(set) var state: TripPlanState = .idle
    private(set) var routePlan: RoutePlan?
    private(set) var origin: RouteWaypoint?
    private(set) var destination: RouteWaypoint?
    private(set) var stop: RouteWaypoint?
    private(set) var selectedRouteID: UUID?
    private(set) var departureDate: Date?

    private let directionsService: DirectionsService
    private var planTask: Task<Void, Never>?
    private let maxAlternatives = 3
    private let currentLocationName = "Current location"

    init(directionsService: DirectionsService) {
        self.directionsService = directionsService
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
        cancelPlan()
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
                    stop: stopValue
                )
                self.state = .loaded
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
    }

    private func applyRoute(
        alternatives: [RouteAlternative],
        origin: RouteWaypoint,
        destination: RouteWaypoint,
        stop: RouteWaypoint?
    ) {
        let selected = alternatives.first?.id
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

    private func cancelPlan() {
        planTask?.cancel()
        planTask = nil
    }
}
