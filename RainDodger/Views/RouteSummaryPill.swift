//
//  RouteSummaryPill.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import SwiftUI
import CoreLocation

struct RouteSummaryPill: View {
    let viewModel: TripPlannerViewModel
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Text(content)
                .font(.headline)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(Capsule().fill(backing))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to reopen trip planner")
        .accessibilityAddTraits(.isButton)
    }

    private var content: String {
        guard let route = selectedRoute else { return "Calculating…" }
        return "\(Int(route.travelTime / 60)) min · \(distanceText(route.distance))"
    }

    private var accessibilityLabel: String {
        guard let route = selectedRoute else { return "Route summary, calculating route" }
        return "Route summary, \(Int(route.travelTime / 60)) minutes, \(distanceSpoken(route.distance))"
    }

    private var selectedRoute: RouteAlternative? {
        guard viewModel.state != .loading, let plan = viewModel.routePlan else { return nil }
        return plan.alternatives.first(where: { $0.id == plan.selectedRouteID }) ?? plan.alternatives.first
    }

    private func distanceText(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        }
        return "\(Int(distance / 1000)) km"
    }

    private func distanceSpoken(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) meters"
        }
        return "\(Int(distance / 1000)) kilometers"
    }

    private var backing: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
}

#Preview {
    RouteSummaryPill(
        viewModel: TripPlannerViewModel(
            directionsService: MockDirectionsService(),
            weatherService: MockWeatherService()
        ),
        onTap: {}
    )
    .padding(16)
}