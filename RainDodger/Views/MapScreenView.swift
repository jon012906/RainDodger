//
//  MapScreenView.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI
import MapKit

struct MapScreenView: View {
    let viewModel: MapViewModel

    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            ZStack {
                map

                if viewModel.authorizationState == .denied {
                    LocationPermissionOverlay(onOpenSettings: openSettings)
                }
            }
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    CompassControl(
                        heading: viewModel.heading,
                        onTap: viewModel.resetNorthAndRecenter
                    )
                    RecenterButton(onRecenter: viewModel.recenter)
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 12) {
                    if let locationErrorMessage = viewModel.locationErrorMessage {
                        LocationErrorCard(
                            message: locationErrorMessage,
                            onRetry: viewModel.retryLocation
                        )
                    }
                    DestinationSearchField(onTap: viewModel.searchFieldTapped)
                }
                .padding(.horizontal, isLandscape ? 0 : 16)
                .padding(.bottom, isLandscape ? 8 : 12)
            }
            .overlay {
                if viewModel.showComingSoon {
                    ComingSoonStub(
                        message: viewModel.comingSoonMessage,
                        onDismiss: viewModel.dismissComingSoon
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: viewModel.showComingSoon)
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onChange(of: viewModel.cameraIntent) { _, intent in
            guard let intent else { return }
            switch intent {
            case .recenter, .resetNorthAndRecenter:
                withAnimation {
                    cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
                }
            }
            viewModel.consumeCameraIntent()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshAuthorizationState()
            }
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct LocationErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: onRetry)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Location error")
        .accessibilityHint("Double tap Retry to try again")
    }
}

#Preview {
    MapScreenView(viewModel: MapViewModel(locationService: MockLocationService()))
}
