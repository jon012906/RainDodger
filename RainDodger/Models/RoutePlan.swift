//
//  RoutePlan.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import Foundation
import CoreLocation
import MapKit

struct RouteWaypoint: Identifiable, Hashable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let categorySymbol: String?

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        categorySymbol: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.categorySymbol = categorySymbol
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RouteAlternative: Identifiable {
    let id: UUID
    let distance: CLLocationDistance
    let travelTime: TimeInterval
    let polyline: MKPolyline
    let coordinatePoints: [CLLocationCoordinate2D]

    init(
        id: UUID = UUID(),
        distance: CLLocationDistance,
        travelTime: TimeInterval,
        polyline: MKPolyline,
        coordinatePoints: [CLLocationCoordinate2D]
    ) {
        self.id = id
        self.distance = distance
        self.travelTime = travelTime
        self.polyline = polyline
        self.coordinatePoints = coordinatePoints
    }
}

struct RoutePlan {
    let origin: RouteWaypoint?
    let destination: RouteWaypoint
    let stop: RouteWaypoint?
    let alternatives: [RouteAlternative]
    let selectedRouteID: UUID?

    init(
        origin: RouteWaypoint?,
        destination: RouteWaypoint,
        stop: RouteWaypoint?,
        alternatives: [RouteAlternative],
        selectedRouteID: UUID?
    ) {
        self.origin = origin
        self.destination = destination
        self.stop = stop
        self.alternatives = alternatives
        self.selectedRouteID = selectedRouteID
    }
}
