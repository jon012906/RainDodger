//
//  ComingSoonStub.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI

struct ComingSoonStub: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")

            VStack(spacing: 14) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 48)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            AccessibilityNotification.Announcement(message).post()
        }
    }
}

#Preview {
    ComingSoonStub(message: "Search is coming soon", onDismiss: {})
}
