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
            coordinatePoints: points
        )
    }

    private func stitch(_ firstLeg: MKRoute, _ secondLeg: MKRoute) -> RouteAlternative {
        let points = coordinates(from: firstLeg.polyline) + coordinates(from: secondLeg.polyline)
        let polyline = MKPolyline(coordinates: points, count: points.count)
        return RouteAlternative(
            distance: firstLeg.distance + secondLeg.distance,
            travelTime: firstLeg.expectedTravelTime + secondLeg.expectedTravelTime,
            polyline: polyline,
            coordinatePoints: points
        )
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
        return RouteAlternative(
            distance: firstRoute.distance + secondRoute.distance,
            travelTime: firstRoute.travelTime + secondRoute.travelTime,
            polyline: polyline,
            coordinatePoints: points
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
                coordinatePoints: points
            )
        }
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
