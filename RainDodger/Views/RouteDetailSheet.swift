//
//  RouteDetailSheet.swift
//  RainDodger
//
//  Created by Jon on 10/09/26.
//

import SwiftUI
import CoreLocation

struct RouteDetailSheet: View {
    let viewModel: TripPlannerViewModel
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            header
            stateArea
            content
            if showsCheckButton {
                checkRouteButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.searchBackground)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 48, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to routes")
            .accessibilityHint("Double tap to return to route options")

            Spacer(minLength: 0)

            Text("Route details")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 48, height: 44)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var stateArea: some View {
        switch viewModel.weatherState {
        case .loading:
            checkingRow
        case .unavailable:
            unavailableNote
        case .idle, .loaded:
            if hasForecast {
                summaryRow
            }
        }
    }

    private var summaryRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                Text("Rain on \(wetDistanceText)")
                Text("of \(totalDistanceText)")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Rain on \(wetDistanceText)")
                Text("of \(totalDistanceText)")
            }
        }
        .font(.rdRowName)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summaryAccessibilityLabel)
    }

    private var checkingRow: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)
            Text("Checking rain along your route…")
                .font(.rdRowStreet)
                .foregroundStyle(Color.secondary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Checking rain along your route")
    }

    private var unavailableNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .accessibilityHidden(true)
            Text("Live rain unavailable")
                .font(.rdRowStreet)
                .foregroundStyle(Color.primary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live rain unavailable. Showing route without rain forecast.")
    }

    @ViewBuilder
    private var content: some View {
        if let alternative = selectedAlternative, !alternative.steps.isEmpty {
            stepList(alternative.steps)
        } else {
            emptyState
        }
    }

    private func stepList(_ steps: [RouteStep]) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    if index > 0 {
                        hairline
                    }
                    RouteStepRow(step: step)
                }
            }
            .background(rowBacking, in: RoundedRectangle(cornerRadius: 16))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var emptyState: some View {
        Text("Turn-by-turn directions unavailable for this route")
            .font(.rdRowStreet)
            .foregroundStyle(Color.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding(.horizontal, 8)
    }

    private var checkRouteButton: some View {
        Button(action: viewModel.checkRoute) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.rain")
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityHidden(true)
                Text("Check route for rain")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.checkRouteBlue))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Check route for rain")
        .accessibilityHint("Double tap to check the route for rain")
    }

    private var selectedAlternative: RouteAlternative? {
        guard let plan = viewModel.routePlan else { return nil }
        return plan.alternatives.first(where: { $0.id == plan.selectedRouteID }) ?? plan.alternatives.first
    }

    private var hasForecast: Bool {
        guard let alternative = selectedAlternative else { return false }
        return viewModel.weatherState == .loaded && !alternative.rainSegments.isEmpty
    }

    private var showsCheckButton: Bool {
        guard selectedAlternative != nil else { return false }
        return viewModel.weatherState != .loading
            && viewModel.weatherState != .unavailable
            && !hasForecast
    }

    private var wetDistanceText: String {
        guard let alternative = selectedAlternative else { return "0 km" }
        return "\(Int((RainMetrics.wetDistance(for: alternative) / 1000).rounded())) km"
    }

    private var totalDistanceText: String {
        guard let alternative = selectedAlternative else { return "0 km" }
        return "\(Int((alternative.distance / 1000).rounded())) km"
    }

    private var summaryAccessibilityLabel: String {
        guard let alternative = selectedAlternative else {
            return "Rain on 0 kilometers of 0 kilometers, rain 50 percent or more"
        }
        let wet = Int((RainMetrics.wetDistance(for: alternative) / 1000).rounded())
        let total = Int((alternative.distance / 1000).rounded())
        return "Rain on \(wet) kilometers of \(total) kilometers, rain 50 percent or more"
    }

    private var rowBacking: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color.searchElement
    }
}

#Preview {
    let viewModel = TripPlannerViewModel(
        directionsService: MockDirectionsService(),
        weatherService: MockWeatherService()
    )
    viewModel.updateDestination(
        RouteWaypoint(name: "Airport", latitude: 52.16, longitude: 20.97, categorySymbol: "airplane")
    )
    viewModel.setOriginFromCurrentLocation(CLLocationCoordinate2D(latitude: 52.229, longitude: 21.010))
    return RouteDetailSheet(viewModel: viewModel, onBack: {})
}

#Preview("Empty steps") {
    let viewModel = TripPlannerViewModel(
        directionsService: MockDirectionsService(),
        weatherService: MockWeatherService()
    )
    return RouteDetailSheet(viewModel: viewModel, onBack: {})
}