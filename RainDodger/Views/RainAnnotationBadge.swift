//
//  RainAnnotationBadge.swift
//  RainDodger
//
//  Created by Jon on 12/09/26.
//

import SwiftUI

struct RainAnnotationBadge: View {
    let rainChance: Double
    let arrivalDate: Date

    private var rainRisk: RainRisk {
        if rainChance < 0.25 { return .low }
        if rainChance < 0.50 { return .moderate }
        if rainChance < 0.75 { return .high }
        return .veryHigh
    }

    private var timeText: String {
        arrivalDate.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: rainRisk.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)

            Text(rainRisk.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(timeText)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 72)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.rainAnnotationBackground)
        )
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rainRisk.label) at \(timeText), \(Int(rainChance * 100)) percent chance")
    }
}

#Preview {
    let now = Date()
    HStack(spacing: 16) {
        RainAnnotationBadge(
            rainChance: 0.15,
            arrivalDate: now.addingTimeInterval(3600)
        )
        RainAnnotationBadge(
            rainChance: 0.45,
            arrivalDate: now.addingTimeInterval(5400)
        )
        RainAnnotationBadge(
            rainChance: 0.91,
            arrivalDate: now.addingTimeInterval(7200)
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
