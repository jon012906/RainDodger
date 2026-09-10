//
//  WeatherLoadingOverlay.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import SwiftUI

struct WeatherLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Checking rain along your route…")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: 280)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Checking rain along your route")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {}
    }
}

#Preview {
    WeatherLoadingOverlay()
}