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

struct RainSegment: Identifiable {
    let id: UUID
    let index: Int
    let coordinate: CLLocationCoordinate2D
    let distanceFromStart: CLLocationDistance
    let arrivalDate: Date
    let rainChance: Double

    init(
        id: UUID = UUID(),
        index: Int,
        coordinate: CLLocationCoordinate2D,
        distanceFromStart: CLLocationDistance,
        arrivalDate: Date,
        rainChance: Double
    ) {
        self.id = id
        self.index = index
        self.coordinate = coordinate
        self.distanceFromStart = distanceFromStart
        self.arrivalDate = arrivalDate
        self.rainChance = rainChance
    }
}

struct WetStretch: Identifiable {
    let id: Int
    let startCoordinate: CLLocationCoordinate2D
    let arrivalDate: Date
    let rainChance: Double
    let distanceFromStart: CLLocationDistance

    init(
        startIndex: Int,
        startCoordinate: CLLocationCoordinate2D,
        arrivalDate: Date,
        rainChance: Double,
        distanceFromStart: CLLocationDistance
    ) {
        self.id = startIndex
        self.startCoordinate = startCoordinate
        self.arrivalDate = arrivalDate
        self.rainChance = rainChance
        self.distanceFromStart = distanceFromStart
    }
}

struct RouteAlternative: Identifiable {
    let id: UUID
    let distance: CLLocationDistance
    let travelTime: TimeInterval
    let polyline: MKPolyline
    let coordinatePoints: [CLLocationCoordinate2D]
    let rainSegments: [RainSegment]
    let steps: [RouteStep]

    init(
        id: UUID = UUID(),
        distance: CLLocationDistance,
        travelTime: TimeInterval,
        polyline: MKPolyline,
        coordinatePoints: [CLLocationCoordinate2D],
        rainSegments: [RainSegment] = [],
        steps: [RouteStep] = []
    ) {
        self.id = id
        self.distance = distance
        self.travelTime = travelTime
        self.polyline = polyline
        self.coordinatePoints = coordinatePoints
        self.rainSegments = rainSegments
        self.steps = steps
    }
}

enum RainMetrics {
    static let wetThreshold: Double = 0.5
    static let maxWetStretchBadges = 3

    static func wetDistance(for alternative: RouteAlternative) -> CLLocationDistance {
        let segments = alternative.rainSegments
        guard !segments.isEmpty else { return 0 }
        var wet: CLLocationDistance = 0
        for (index, segment) in segments.enumerated() {
            let end = index + 1 < segments.count ? segments[index + 1].distanceFromStart : alternative.distance
            let length = end - segment.distanceFromStart
            if segment.rainChance >= wetThreshold {
                wet += length
            }
        }
        return wet
    }

    static func wetStretches(for alternative: RouteAlternative) -> [WetStretch] {
        var stretches: [WetStretch] = []
        var runStart: RainSegment?
        var runMaxChance: Double = 0
        for segment in alternative.rainSegments {
            if segment.rainChance >= wetThreshold {
                if runStart == nil {
                    runStart = segment
                    runMaxChance = segment.rainChance
                } else {
                    runMaxChance = max(runMaxChance, segment.rainChance)
                }
            } else if let start = runStart {
                stretches.append(WetStretch(
                    startIndex: start.index,
                    startCoordinate: start.coordinate,
                    arrivalDate: start.arrivalDate,
                    rainChance: runMaxChance,
                    distanceFromStart: start.distanceFromStart
                ))
                runStart = nil
                runMaxChance = 0
            }
        }
        if let start = runStart {
            stretches.append(WetStretch(
                startIndex: start.index,
                startCoordinate: start.coordinate,
                arrivalDate: start.arrivalDate,
                rainChance: runMaxChance,
                distanceFromStart: start.distanceFromStart
            ))
        }
        return stretches
    }

    static func mappedSteps(
        _ steps: [RouteStep],
        rainSegments: [RainSegment],
        totalDistance: CLLocationDistance
    ) -> [RouteStep] {
        guard !rainSegments.isEmpty else {
            return steps.map { step in
                var mapped = step
                mapped.rainChance = nil
                mapped.wet = false
                return mapped
            }
        }
        return steps.enumerated().map { offset, step in
            let end = offset + 1 < steps.count ? steps[offset + 1].distanceFromStart : max(totalDistance, step.distanceFromStart)
            let inRange = rainSegments.filter {
                $0.distanceFromStart >= step.distanceFromStart && $0.distanceFromStart < end
            }
            let midpoint = (step.distanceFromStart + end) / 2
            let representative = inRange.map(\.rainChance).max()
                ?? nearestRainChance(to: midpoint, in: rainSegments)
            let arrival = inRange.first?.arrivalDate ?? nearestArrivalDate(to: midpoint, in: rainSegments)
            var mapped = step
            mapped.rainChance = representative
            mapped.wet = (representative ?? 0) >= wetThreshold
            mapped.arrivalDate = arrival
            return mapped
        }
    }

    private static func nearestArrivalDate(to distance: CLLocationDistance, in segments: [RainSegment]) -> Date? {
        segments.min {
            abs($0.distanceFromStart - distance) < abs($1.distanceFromStart - distance)
        }?.arrivalDate
    }

    private static func nearestRainChance(to distance: CLLocationDistance, in segments: [RainSegment]) -> Double? {
        segments.min {
            abs($0.distanceFromStart - distance) < abs($1.distanceFromStart - distance)
        }?.rainChance
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
