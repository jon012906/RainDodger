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
    let wetStretches: [WetStretch]
    var isDry: Bool = false

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
            if !isDry {
                Text(wetDistanceText)
                    .font(.rdRowStreet)
                    .foregroundStyle(Color.primary)
            }
            if !isDry, !visibleWetStretches.isEmpty {
                timeLine
                    .font(.rdRowStreet)
            }
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

    private var visibleWetStretches: [WetStretch] {
        Array(wetStretches.prefix(RainMetrics.maxWetStretchBadges))
    }

    private var additionalWetStretchCount: Int {
        max(wetStretches.count - visibleWetStretches.count, 0)
    }

    private var timeLine: Text {
        var attributed = AttributedString("Rain at")
        attributed.foregroundColor = Color.primary
        for (index, stretch) in visibleWetStretches.enumerated() {
            if index > 0 {
                var separator = AttributedString(" ·")
                separator.foregroundColor = Color.secondary
                attributed += separator
            }
            var time = AttributedString(" \(formattedTime(stretch.arrivalDate))")
            time.foregroundColor = Color.primary
            attributed += time
        }
        if additionalWetStretchCount > 0 {
            var more = AttributedString(" +\(additionalWetStretchCount) more")
            more.foregroundColor = Color.secondary
            attributed += more
        }
        return Text(attributed)
    }

    private func formattedTime(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
    }

    private var accessibilityLabel: String {
        if isDry {
            return "Rain legend. Dry, under 30 percent. Light, 30 to 60 percent. Heavy rain, 60 percent or more. No rain on this route."
        }
        let wetSpoken = "\(Int((wetDistance / 1000).rounded())) kilometers"
        let totalSpoken = "\(Int((totalDistance / 1000).rounded())) kilometers"
        var label = "Rain legend. Dry, under 30 percent. Light, 30 to 60 percent. Heavy rain, 60 percent or more. \(wetSpoken) of \(totalSpoken) with rain 50 percent or more."
        if !visibleWetStretches.isEmpty {
            label += " Rain likely at \(spokenTimeList(visibleWetStretches.map(\.arrivalDate)))."
        }
        if additionalWetStretchCount > 0 {
            label += " \(additionalWetStretchCount) more wet stretches."
        }
        return label
    }

    private func spokenTimeList(_ dates: [Date]) -> String {
        let times = dates.map(formattedTime)
        switch times.count {
        case 0: return ""
        case 1: return times[0]
        case 2: return "\(times[0]) and \(times[1])"
        default:
            return "\(times.dropLast().joined(separator: ", ")), and \(times[times.count - 1])"
        }
    }
}

#Preview {
    let now = Date()
    VStack(alignment: .leading, spacing: 16) {
        RainLegend(
            wetDistance: 14000,
            totalDistance: 40000,
            wetStretches: [
                WetStretch(
                    startIndex: 0,
                    startCoordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.42),
                    arrivalDate: now.addingTimeInterval(3600),
                    rainChance: 0.72,
                    distanceFromStart: 5000
                ),
                WetStretch(
                    startIndex: 1,
                    startCoordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.43),
                    arrivalDate: now.addingTimeInterval(5400),
                    rainChance: 0.55,
                    distanceFromStart: 12000
                ),
                WetStretch(
                    startIndex: 2,
                    startCoordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.44),
                    arrivalDate: now.addingTimeInterval(7200),
                    rainChance: 0.81,
                    distanceFromStart: 18000
                ),
                WetStretch(
                    startIndex: 3,
                    startCoordinate: CLLocationCoordinate2D(latitude: 37.80, longitude: -122.45),
                    arrivalDate: now.addingTimeInterval(9000),
                    rainChance: 0.63,
                    distanceFromStart: 24000
                ),
                WetStretch(
                    startIndex: 4,
                    startCoordinate: CLLocationCoordinate2D(latitude: 37.81, longitude: -122.46),
                    arrivalDate: now.addingTimeInterval(10800),
                    rainChance: 0.67,
                    distanceFromStart: 30000
                )
            ]
        )
        RainLegend(
            wetDistance: 0,
            totalDistance: 40000,
            wetStretches: []
        )
    }
    .padding(16)
}