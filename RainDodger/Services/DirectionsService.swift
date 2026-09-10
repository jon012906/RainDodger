//
//  DirectionsService.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import Foundation
import CoreLocation
import MapKit

protocol DirectionsService: AnyObject {
    func route(
        from origin: RouteWaypoint,
        to destination: RouteWaypoint,
        via stop: RouteWaypoint?,
        maxAlternatives: Int,
        departureDate: Date?
    ) async throws -> [RouteAlternative]
}

@MainActor
final class LiveDirectionsService: DirectionsService {
    func route(
        from origin: RouteWaypoint,
        to destination: RouteWaypoint,
        via stop: RouteWaypoint?,
        maxAlternatives: Int,
        departureDate: Date?
    ) async throws -> [RouteAlternative] {
        if let stop {
            let firstLeg = try await calculate(request(from: origin, to: stop, departureDate: departureDate))
            let secondLeg = try await calculate(request(from: stop, to: destination, departureDate: departureDate))
            guard let firstRoute = firstLeg.routes.first, let secondRoute = secondLeg.routes.first else {
                throw DirectionsError.emptyResponse
            }
            return [stitch(firstRoute, secondRoute)]
        }

        let response = try await calculate(request(from: origin, to: destination, departureDate: departureDate))
        let alternatives = response.routes.map(mapRoute)
        if maxAlternatives > 0, alternatives.count > maxAlternatives {
            return Array(alternatives.prefix(maxAlternatives))
        }
        return alternatives
    }

    private func request(
        from origin: RouteWaypoint,
        to destination: RouteWaypoint,
        departureDate: Date?
    ) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: origin.latitude, longitude: origin.longitude), address: nil)
        request.source?.name = origin.name
        request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
        request.destination?.name = destination.name
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        if let departureDate {
            request.departureDate = departureDate
        }
        return request
    }

    private func calculate(_ request: MKDirections.Request) async throws -> MKDirections.Response {
        try await withCheckedThrowingContinuation { continuation in
            MKDirections(request: request).calculate { response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: DirectionsError.emptyResponse)
                }
            }
        }
    }

    private func mapRoute(_ route: MKRoute) -> RouteAlternative {
        let points = coordinates(from: route.polyline)
        return RouteAlternative(
            distance: route.distance,
            travelTime: route.expectedTravelTime,
            polyline: route.polyline,
            coordinatePoints: points,
            steps: steps(from: route.steps, totalDistance: route.distance)
        )
    }

    private func stitch(_ firstLeg: MKRoute, _ secondLeg: MKRoute) -> RouteAlternative {
        let points = coordinates(from: firstLeg.polyline) + coordinates(from: secondLeg.polyline)
        let polyline = MKPolyline(coordinates: points, count: points.count)
        let firstSteps = steps(from: firstLeg.steps, totalDistance: firstLeg.distance)
        let secondSteps = steps(
            from: secondLeg.steps,
            totalDistance: secondLeg.distance,
            indexOffset: firstSteps.count,
            distanceOffset: firstLeg.distance
        )
        return RouteAlternative(
            distance: firstLeg.distance + secondLeg.distance,
            travelTime: firstLeg.expectedTravelTime + secondLeg.expectedTravelTime,
            polyline: polyline,
            coordinatePoints: points,
            steps: firstSteps + secondSteps
        )
    }

    private func steps(
        from routeSteps: [MKRoute.Step],
        totalDistance: CLLocationDistance,
        indexOffset: Int = 0,
        distanceOffset: CLLocationDistance = 0
    ) -> [RouteStep] {
        let rawTotal = routeSteps.map(\.distance).reduce(0, +)
        let scale = totalDistance / max(rawTotal, 1)
        var cumulative = distanceOffset
        return routeSteps.enumerated().map { offset, routeStep in
            let index = indexOffset + offset
            let step = RouteStep(
                index: index,
                instruction: routeStep.instructions,
                distance: routeStep.distance,
                turnType: parsedTurnType(for: routeStep.instructions, index: index),
                polyline: routeStep.polyline,
                coordinatePoints: coordinates(from: routeStep.polyline),
                distanceFromStart: cumulative
            )
            cumulative += routeStep.distance * scale
            return step
        }
    }

    private func parsedTurnType(for instruction: String, index: Int) -> RouteTurnType {
        let parsed = RouteTurnType(instruction: instruction)
        if parsed == .other, index == 0 {
            return .straight
        }
        return parsed
    }

    private func coordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        let points = polyline.points()
        let count = polyline.pointCount
        return (0..<count).map { points[$0].coordinate }
    }
}

private enum DirectionsError: Error {
    case emptyResponse
}

@MainActor
final class MockDirectionsService: DirectionsService {
    func route(
        from origin: RouteWaypoint,
        to destination: RouteWaypoint,
        via stop: RouteWaypoint?,
        maxAlternatives: Int,
        departureDate: Date?
    ) async throws -> [RouteAlternative] {
        try? await Task.sleep(for: .milliseconds(150))
        if let stop {
            return [stitchedAlternative(origin: origin.coordinate, stop: stop.coordinate, destination: destination.coordinate)]
        }
        var alternatives = buildAlternatives(from: origin.coordinate, to: destination.coordinate)
        if maxAlternatives > 0, alternatives.count > maxAlternatives {
            alternatives = Array(alternatives.prefix(maxAlternatives))
        }
        return alternatives
    }

    private func stitchedAlternative(
        origin: CLLocationCoordinate2D,
        stop: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) -> RouteAlternative {
        let firstLeg = buildAlternatives(from: origin, to: stop)
        let secondLeg = buildAlternatives(from: stop, to: destination)
        let firstRoute = firstLeg[0]
        let secondRoute = secondLeg[0]
        let points = firstRoute.coordinatePoints + secondRoute.coordinatePoints
        let polyline = MKPolyline(coordinates: points, count: points.count)
        let steps = firstRoute.steps + scriptedSteps(
            from: stop,
            to: destination,
            distance: secondRoute.distance,
            indexOffset: firstRoute.steps.count,
            distanceOffset: firstRoute.distance
        )
        return RouteAlternative(
            distance: firstRoute.distance + secondRoute.distance,
            travelTime: firstRoute.travelTime + secondRoute.travelTime,
            polyline: polyline,
            coordinatePoints: points,
            steps: steps
        )
    }

    private func buildAlternatives(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> [RouteAlternative] {
        let basePoints = interpolate(from: start, to: end, count: 6)
        let offsets: [CLLocationDegrees] = [0.001, -0.003, 0.005]
        return offsets.enumerated().map { index, offset in
            let points = basePoints.enumerated().map { pointIndex, point in
                if pointIndex == 0 || pointIndex == basePoints.count - 1 {
                    return point
                }
                return CLLocationCoordinate2D(latitude: point.latitude + offset, longitude: point.longitude)
            }
            let polyline = MKPolyline(coordinates: points, count: points.count)
            let segmentDistance: CLLocationDistance = 900
            let distance = segmentDistance * Double(points.count - 1) * (1 + 0.15 * Double(index))
            let travelTime = distance / 14.0
            return RouteAlternative(
                distance: distance,
                travelTime: travelTime,
                polyline: polyline,
                coordinatePoints: points,
                steps: scriptedSteps(from: start, to: end, distance: distance)
            )
        }
    }

    private func scriptedSteps(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        distance: CLLocationDistance,
        indexOffset: Int = 0,
        distanceOffset: CLLocationDistance = 0
    ) -> [RouteStep] {
        let script: [(instruction: String, turnType: RouteTurnType, weight: Double)] = [
            ("Depart and head east on Main Street", .depart, 0.35),
            ("Continue straight for 5 kilometers", .straight, 0.15),
            ("At the roundabout, take the second exit", .roundabout, 0.08),
            ("Slight right onto the ramp", .slightRight, 0.07),
            ("Merge onto Highway 1", .merge, 0.20),
            ("Keep left to stay on Highway 1", .keepLeft, 0.07),
            ("Make a U-turn at the next intersection", .uTurn, 0.04),
            ("Your destination is on the right", .arrive, 0.04)
        ]
        let totalWeight = script.reduce(0) { $0 + $1.weight }
        var cumulative = distanceOffset
        var fraction: Double = 0
        return script.enumerated().map { index, entry in
            let nextFraction = fraction + entry.weight / totalWeight
            let stepPoints = interpolate(
                from: point(from: start, to: end, fraction: fraction),
                to: point(from: start, to: end, fraction: nextFraction),
                count: 3
            )
            let stepDistance = distance * entry.weight / totalWeight
            let step = RouteStep(
                index: indexOffset + index,
                instruction: entry.instruction,
                distance: stepDistance,
                turnType: entry.turnType,
                polyline: MKPolyline(coordinates: stepPoints, count: stepPoints.count),
                coordinatePoints: stepPoints,
                distanceFromStart: cumulative
            )
            cumulative += stepDistance
            fraction = nextFraction
            return step
        }
    }

    private func point(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )
    }

    private func interpolate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        count: Int
    ) -> [CLLocationCoordinate2D] {
        (0..<count).map { index in
            let t = Double(index) / Double(count - 1)
            return CLLocationCoordinate2D(
                latitude: start.latitude + (end.latitude - start.latitude) * t,
                longitude: start.longitude + (end.longitude - start.longitude) * t
            )
        }
    }
}
