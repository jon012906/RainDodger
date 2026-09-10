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
            VStack(spacing: 4) {
                Capsule()
                    .fill(grabberColor)
                    .frame(width: 36, height: 5)
                    .accessibilityHidden(true)
                Text(content)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(backing))
            .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height < -40 {
                    onTap()
                }
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap or drag up to reopen trip planner")
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

    private var grabberColor: Color {
        colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)
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