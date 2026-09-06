//
//  LocationPermissionOverlay.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI

struct LocationPermissionOverlay: View {
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.secondary)
                Text("Location Access Needed")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Rain Dodger needs your location to recenter and show the compass")
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 44)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minHeight: 44)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    LocationPermissionOverlay(onOpenSettings: {})
}
