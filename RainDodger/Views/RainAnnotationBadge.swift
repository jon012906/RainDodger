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

    private var band: RainBand {
        RainBand(rainChance: rainChance)
    }

    private var timeText: String {
        arrivalDate.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)

            Text("raining")
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
        .accessibilityLabel("Rain at \(timeText), \(Int(rainChance * 100)) percent chance")
    }
}

#Preview("Rain Badge — 30% vs 85%") {
    let now = Date()
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                RainAnnotationBadge(
                    rainChance: 0.30,
                    arrivalDate: now.addingTimeInterval(1800)
                )
                Text("30% — Light")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                RainAnnotationBadge(
                    rainChance: 0.85,
                    arrivalDate: now.addingTimeInterval(3600)
                )
                Text("85% — Heavy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding(32)
    .background(Color(.systemBackground))
}
