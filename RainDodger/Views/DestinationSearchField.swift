//
//  DestinationSearchField.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI

struct DestinationSearchField: View {
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Text("Your Destination…")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
                avatar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(capsuleBackground))
            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your destination field")
        .accessibilityHint("Double tap to search")
        .accessibilityValue("Your Destination…")
    }

    private var avatar: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray))
            }
    }

    private var capsuleBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
}

#Preview {
    DestinationSearchField(onTap: {})
        .padding(16)
}
