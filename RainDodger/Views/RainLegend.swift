//
//  RainLegend.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import SwiftUI
import CoreLocation

enum RainBand: CaseIterable {
    case dry
    case light
    case heavy

    init(rainChance: Double) {
        if rainChance < 0.30 {
            self = .dry
        } else if rainChance < 0.60 {
            self = .light
        } else {
            self = .heavy
        }
    }

    var color: Color {
        switch self {
        case .dry: Color.blue
        case .light: Color.yellow
        case .heavy: Color.red
        }
    }

    var label: String {
        switch self {
        case .dry: "Dry"
        case .light: "Light"
        case .heavy: "Heavy rain"
        }
    }

    var range: String {
        switch self {
        case .dry: "<30%"
        case .light: "30–60%"
        case .heavy: "≥60%"
        }
    }
}

struct RainLegend: View {
    let wetDistance: CLLocationDistance
    let totalDistance: CLLocationDistance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    chipRow
                }
                VStack(alignment: .leading, spacing: 6) {
                    chipRow
                }
            }
            Text(wetDistanceText)
                .font(.rdRowStreet)
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var chipRow: some View {
        ForEach(RainBand.allCases, id: \.self) { band in
            HStack(spacing: 6) {
                Circle()
                    .fill(band.color)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                Text(band.label)
                    .font(.rdRowStreet)
                    .foregroundStyle(Color.primary)
                Text(band.range)
                    .font(.rdRowStreet)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var wetDistanceText: String {
        "\(formatted(wetDistance)) of \(formatted(totalDistance)) with rain ≥ 50%"
    }

    private func formatted(_ distance: CLLocationDistance) -> String {
        "\(Int((distance / 1000).rounded())) km"
    }

    private var accessibilityLabel: String {
        let wetSpoken = "\(Int((wetDistance / 1000).rounded())) kilometers"
        let totalSpoken = "\(Int((totalDistance / 1000).rounded())) kilometers"
        return "Rain legend. Dry, under 30 percent. Light, 30 to 60 percent. Heavy rain, 60 percent or more. \(wetSpoken) of \(totalSpoken) with rain 50 percent or more."
    }
}

#Preview {
    RainLegend(wetDistance: 14000, totalDistance: 40000)
        .padding(16)
}