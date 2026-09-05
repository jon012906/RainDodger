//
//  RecenterButton.swift
//  RainDodger
//
//  Created by Jon on 05/09/26.
//

import SwiftUI

struct RecenterButton: View {
    static let size: CGFloat = 56

    let onRecenter: () -> Void

    var body: some View {
        Button(action: onRecenter) {
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(darkCircleColor)
                .frame(width: Self.size, height: Self.size)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recenter to my location")
    }

    private var darkCircleColor: Color {
        Color(red: 0.11, green: 0.11, blue: 0.12)
    }
}

#Preview {
    RecenterButton(onRecenter: {})
        .padding(16)
}
