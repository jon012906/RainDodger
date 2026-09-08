//
//  RouteCard.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import SwiftUI
import MapKit

struct RouteCard: View {
    let index: Int
    let alternative: RouteAlternative
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(alternative.travelTime / 60)) min")
                        .font(.rdRowName)
                        .foregroundStyle(Color.primary)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.blue)
                            .accessibilityHidden(true)
                    }
                }
                Text(distanceText)
                    .font(.rdRowStreet)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 132, minHeight: 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backing)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to select this route")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private var distanceText: String {
        if alternative.distance < 1000 {
            return "\(Int(alternative.distance)) m"
        }
        return "\(Int(alternative.distance / 1000)) km"
    }

    private var accessibilityLabel: String {
        let distance: String
        if alternative.distance < 1000 {
            distance = "\(Int(alternative.distance)) meters"
        } else {
            distance = "\(Int(alternative.distance / 1000)) km"
        }
        return "Route \(index + 1), \(Int(alternative.travelTime / 60)) minutes, \(distance), \(isSelected ? "selected" : "not selected")"
    }

    private var backing: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color.searchElement
    }
}

#Preview {
    let points = [
        CLLocationCoordinate2D(latitude: 52.229, longitude: 21.010),
        CLLocationCoordinate2D(latitude: 52.242, longitude: 21.015)
    ]
    return HStack(spacing: 12) {
        RouteCard(
            index: 0,
            alternative: RouteAlternative(
                distance: 14000,
                travelTime: 1500,
                polyline: MKPolyline(coordinates: points, count: points.count),
                coordinatePoints: points
            ),
            isSelected: true,
            onTap: {}
        )
        RouteCard(
            index: 1,
            alternative: RouteAlternative(
                distance: 16400,
                travelTime: 1740,
                polyline: MKPolyline(coordinates: points, count: points.count),
                coordinatePoints: points
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding(16)
    .background(Color.searchBackground)
}