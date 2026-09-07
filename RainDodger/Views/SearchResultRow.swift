//
//  SearchResultRow.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                Image(systemName: result.categorySymbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.rdRowName)
                    .foregroundStyle(Color.primary)
                Text(result.street)
                    .font(.rdRowStreet)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.searchElement))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.name), \(result.street)")
        .accessibilityHint("Double tap to select as destination")
    }
}

#Preview {
    SearchResultRow(
        result: SearchResult(
            id: UUID(),
            name: "Restauracja Stary Dom",
            street: "ul. Nowogrodzka 5",
            latitude: 52.2290,
            longitude: 21.0100,
            categorySymbol: "fork.knife"
        )
    )
}
