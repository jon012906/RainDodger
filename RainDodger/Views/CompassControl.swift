//
//  CompassControl.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI
import CoreLocation

struct CompassControl: View {
    static let size: CGFloat = 56

    let heading: CLLocationDirection?
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var rotationDegrees: Double {
        -(heading ?? 0)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(darkCircleColor)
                    .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
                dial
                    .rotationEffect(.degrees(rotationDegrees))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: rotationDegrees)
                topMarker
            }
            .frame(width: Self.size, height: Self.size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compass")
        .accessibilityValue(cardinalValue)
        .accessibilityHint("Double tap to reset to north and recenter")
    }

    private var dial: some View {
        let inset = Self.size / 2 - 15
        return ZStack {
            compassLetter("N", emphasized: true)
                .offset(y: -inset)
            compassLetter("E")
                .offset(x: inset)
            compassLetter("S")
                .offset(y: inset)
            compassLetter("W")
                .offset(x: -inset)
        }
    }

    private func compassLetter(_ letter: String, emphasized: Bool = false) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: emphasized ? .bold : .semibold))
            .foregroundStyle(emphasized ? Color.white : Color.white.opacity(0.72))
    }

    private var topMarker: some View {
        MarkerTriangle()
            .fill(Color.white)
            .frame(width: 8, height: 6)
            .offset(y: -(Self.size / 2 - 8))
    }

    private var cardinalValue: String {
        guard let heading else { return "Unknown direction" }
        let directions = ["North", "North-east", "East", "South-east", "South", "South-west", "West", "North-west"]
        let index = Int((heading + 22.5).truncatingRemainder(dividingBy: 360) / 45) % 8
        return "\(directions[index]), \(Int(heading.rounded())) degrees"
    }

    private var darkCircleColor: Color {
        Color(red: 0.11, green: 0.11, blue: 0.12)
    }
}

private struct MarkerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    CompassControl(heading: 45, onTap: {})
        .padding(16)
}
