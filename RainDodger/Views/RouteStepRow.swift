//
//  RouteStepRow.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteStepRow: View {
    let step: RouteStep

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: step.turnType.symbolName)
                .font(.system(size: 20))
                .foregroundStyle(Color.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(step.instruction)
                .font(.rdRowName)
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailingColumn
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(distanceText)
                .font(.rdRowStreet)
                .foregroundStyle(Color.secondary)
            if step.wet, let rainChance = step.rainChance {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.blue)
                        .accessibilityHidden(true)
                    Text("\(Int((rainChance * 100).rounded()))%")
                        .font(.rdRowStreet)
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var distanceText: String {
        if step.distance < 1000 {
            return "\(Int(step.distance)) m"
        }
        return String(format: "%.1f km", step.distance / 1000)
    }

    private var accessibilityLabel: String {
        let distanceSpoken: String
        if step.distance < 1000 {
            distanceSpoken = "\(Int(step.distance)) meters"
        } else {
            distanceSpoken = String(format: "%.1f kilometers", step.distance / 1000)
        }
        guard step.wet, let rainChance = step.rainChance else {
            return "\(step.instruction), \(distanceSpoken)"
        }
        return "\(step.instruction), \(distanceSpoken), rain \(Int((rainChance * 100).rounded())) percent"
    }
}

private extension RouteTurnType {
    var symbolName: String {
        switch self {
        case .depart: "location.north.fill"
        case .straight: "arrow.up"
        case .turnLeft: "arrow.turn.up.left"
        case .turnRight: "arrow.turn.up.right"
        case .slightLeft: "arrow.up.left"
        case .slightRight: "arrow.up.right"
        case .keepLeft: "arrow.turn.up.left"
        case .keepRight: "arrow.turn.up.right"
        case .merge: "arrow.merge"
        case .roundabout: "arrow.triangle.turn.up.right.circle"
        case .uTurn: "arrow.uturn.left"
        case .arrive: "flag.checkered"
        case .other: "arrow.up"
        }
    }
}

#Preview {
    let points = [
        CLLocationCoordinate2D(latitude: 52.229, longitude: 21.010),
        CLLocationCoordinate2D(latitude: 52.242, longitude: 21.015)
    ]
    let polyline = MKPolyline(coordinates: points, count: points.count)
    return VStack(spacing: 0) {
        RouteStepRow(step: RouteStep(
            index: 0,
            instruction: "Turn left onto Main Street",
            distance: 800,
            turnType: .turnLeft,
            polyline: polyline,
            coordinatePoints: points,
            distanceFromStart: 0,
            rainChance: 0.6,
            wet: true
        ))
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
        RouteStepRow(step: RouteStep(
            index: 1,
            instruction: "Continue straight for 5 kilometers",
            distance: 1200,
            turnType: .straight,
            polyline: polyline,
            coordinatePoints: points,
            distanceFromStart: 800
        ))
    }
    .background(Color.searchElement, in: RoundedRectangle(cornerRadius: 16))
    .padding(16)
    .background(Color.searchBackground)
}
