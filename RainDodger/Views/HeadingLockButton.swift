//
//  HeadingLockButton.swift
//  RainDodger
//
//  Created by Jon on 14/09/26.
//

import SwiftUI

struct HeadingLockButton: View {
    static let size: CGFloat = 56

    let isLocked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isLocked ? "location.north.line.fill" : "location.north.line")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(darkGlyphColor)
                .frame(width: Self.size, height: Self.size)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lock to heading")
        .accessibilityValue(isLocked ? "Locked" : "Unlocked")
        .accessibilityHint("Map and compass follow your heading while locked")
    }

    private var darkGlyphColor: Color {
        Color(red: 0.11, green: 0.11, blue: 0.12)
    }
}

#Preview {
    VStack(spacing: 24) {
        HeadingLockButton(isLocked: false, onToggle: {})
        HeadingLockButton(isLocked: true, onToggle: {})
    }
    .padding(24)
}