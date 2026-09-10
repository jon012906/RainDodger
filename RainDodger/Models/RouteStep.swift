//
//  RouteStep.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import Foundation
import CoreLocation
import MapKit

enum RouteTurnType {
    case depart
    case straight
    case turnLeft
    case turnRight
    case slightLeft
    case slightRight
    case keepLeft
    case keepRight
    case merge
    case roundabout
    case uTurn
    case arrive
    case other

    init(instruction: String) {
        let text = instruction.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch true {
        case text.isEmpty:
            self = .other
        case text.contains("arrive") || text.contains("destination"):
            self = .arrive
        case text.contains("depart") || text.hasPrefix("head "):
            self = .depart
        case text.contains("roundabout") || text.contains("exit"):
            self = .roundabout
        case text.contains("u-turn") || text.contains("u turn") || text.contains("uturn"):
            self = .uTurn
        case text.contains("merge"):
            self = .merge
        case text.contains("keep left"):
            self = .keepLeft
        case text.contains("keep right"):
            self = .keepRight
        case text.contains("slight left") || text.contains("bear left"):
            self = .slightLeft
        case text.contains("slight right") || text.contains("bear right"):
            self = .slightRight
        case text.contains("turn left") || text.contains("left turn"):
            self = .turnLeft
        case text.contains("turn right") || text.contains("right turn"):
            self = .turnRight
        case text.contains("continue") || text.contains("straight"):
            self = .straight
        case text.contains("left"):
            self = .turnLeft
        case text.contains("right"):
            self = .turnRight
        default:
            self = .other
        }
    }
}

struct RouteStep: Identifiable {
    let id: UUID
    let index: Int
    let instruction: String
    let distance: CLLocationDistance
    let turnType: RouteTurnType
    let polyline: MKPolyline
    let coordinatePoints: [CLLocationCoordinate2D]
    let distanceFromStart: CLLocationDistance
    var rainChance: Double?
    var wet: Bool

    init(
        id: UUID = UUID(),
        index: Int,
        instruction: String,
        distance: CLLocationDistance,
        turnType: RouteTurnType,
        polyline: MKPolyline,
        coordinatePoints: [CLLocationCoordinate2D],
        distanceFromStart: CLLocationDistance,
        rainChance: Double? = nil,
        wet: Bool = false
    ) {
        self.id = id
        self.index = index
        self.instruction = instruction
        self.distance = distance
        self.turnType = turnType
        self.polyline = polyline
        self.coordinatePoints = coordinatePoints
        self.distanceFromStart = distanceFromStart
        self.rainChance = rainChance
        self.wet = wet
    }
}