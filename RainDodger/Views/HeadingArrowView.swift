//
//  HeadingArrowView.swift
//  RainDodger
//
//  Created by Jon on 14/09/26.
//

import SwiftUI
import CoreLocation

struct HeadingArrowView: View {
    static let size: CGFloat = 36

    let heading: CLLocationDirection?
    let rotation: CLLocationDirection

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var unwrappedRotation: CLLocationDirection = 0

    init(heading: CLLocationDirection?, rotation: CLLocationDirection) {
        self.heading = heading
        self.rotation = rotation
        _unwrappedRotation = State(initialValue: rotation)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
            Image(systemName: "location.north.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.blue)
        }
        .frame(width: Self.size, height: Self.size)
        .rotationEffect(.degrees(unwrappedRotation))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: unwrappedRotation)
        .onChange(of: rotation) { _, newValue in
            unwrappedRotation = unwrappedAngle(from: newValue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your location")
        .accessibilityValue(cardinalValue ?? "")
    }

    private var cardinalValue: String? {
        guard let heading else { return nil }
        let directions = ["north", "north east", "east", "south east", "south", "south west", "west", "north west"]
        let index = Int((heading + 22.5).truncatingRemainder(dividingBy: 360) / 45) % 8
        return "heading \(directions[index]), \(Int(heading.rounded())) degrees"
    }

    private func unwrappedAngle(from newValue: CLLocationDirection) -> CLLocationDirection {
        var delta = (newValue - unwrappedRotation).truncatingRemainder(dividingBy: 360)
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        return unwrappedRotation + delta
    }
}

#Preview {
    VStack(spacing: 24) {
        HeadingArrowView(heading: 45, rotation: 0)
        HeadingArrowView(heading: 45, rotation: 135)
        HeadingArrowView(heading: nil, rotation: 0)
    }
    .padding(24)
}