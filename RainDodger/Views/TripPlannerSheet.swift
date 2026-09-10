//
//  TripPlannerSheet.swift
//  RainDodger
//
//  Created by Jon on 08/09/26.
//

import SwiftUI
import CoreLocation

struct TripPlannerSheet: View {
    let viewModel: TripPlannerViewModel
    let searchService: DestinationSearchService
    let searchCoordinate: CLLocationCoordinate2D?

    @Environment(\.colorScheme) private var colorScheme
    @State private var searchViewModel: SearchViewModel
    @State private var activeSearch: SearchTarget?
    @State private var isDeparturePickerPresented = false
    @State private var detent: PresentationDetent = .medium
    @State private var showsDetail = false

    init(
        viewModel: TripPlannerViewModel,
        searchService: DestinationSearchService,
        searchCoordinate: CLLocationCoordinate2D?
    ) {
        self.viewModel = viewModel
        self.searchService = searchService
        self.searchCoordinate = searchCoordinate
        _searchViewModel = State(initialValue: SearchViewModel(searchService: searchService))
    }

    private enum SearchTarget: String, Identifiable {
        case origin
        case stop

        var id: String { rawValue }

        var context: SearchContext {
            switch self {
            case .origin: return .origin
            case .stop: return .stop
            }
        }
    }

    private let departureTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    var body: some View {
        Group {
            if showsDetail {
                RouteDetailSheet(viewModel: viewModel) {
                    showsDetail = false
                    detent = .medium
                }
            } else {
                plannerContent
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .sheet(item: $activeSearch) { target in
            SearchPage(
                viewModel: searchViewModel,
                onSelect: { result in handlePick(result, for: target) },
                context: target.context
            )
            .presentationDragIndicator(.visible)
        }
    }

    private var plannerContent: some View {
        VStack(spacing: 12) {
            Text("Direction")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)
            groupedCard
            leaveAtRow
            checkRouteButton
            cardsArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.searchBackground)
    }

    private var groupedCard: some View {
        VStack(spacing: 0) {
            originRow
            hairline
            destinationRow
            hairline
            stopSlot
        }
        .background(rowBacking, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var originRow: some View {
        HStack(spacing: 8) {
            Button {
                presentSearch(.origin)
            } label: {
                HStack(spacing: 12) {
                    rowIcon("location.north.line.fill", color: .blue)
                    labelValue("Origin", value: originValue)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Origin, \(originValue)")
            .accessibilityHint("Double tap to change origin")
            dragHandle
        }
    }

    private var destinationRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                rowIcon(destinationSymbol, color: .orange)
                labelValue("Destination", value: destinationValue, valueLines: 2)
                Spacer(minLength: 0)
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Destination, \(destinationValue)")
            dragHandle
        }
    }

    @ViewBuilder
    private var stopSlot: some View {
        if let stop = viewModel.stop {
            filledStopRow(stop)
        } else {
            emptyStopRow
        }
    }

    private var emptyStopRow: some View {
        HStack(spacing: 8) {
            Button {
                presentSearch(.stop)
            } label: {
                HStack(spacing: 12) {
                    rowIcon("plus", color: .blue)
                    Text("Add stop")
                        .font(.rdSectionHeader)
                        .foregroundStyle(Color.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Add stop")
            dragHandle
        }
    }

    private func filledStopRow(_ stop: RouteWaypoint) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                rowIcon("plus", color: .blue)
                labelValue("Stop", value: stop.name)
                Spacer(minLength: 0)
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Stop, \(stop.name)")
            Button(action: viewModel.removeStop) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove stop")
            dragHandle
        }
    }

    private func rowIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 24)
            .accessibilityHidden(true)
    }

    private func labelValue(_ label: String, value: String, valueLines: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.rdSectionHeader)
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.rdRowName)
                .foregroundStyle(Color.primary)
                .lineLimit(valueLines)
        }
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.secondary)
            .frame(width: 44, height: 44)
            .padding(.trailing, 8)
            .accessibilityHidden(true)
    }

    private var leaveAtRow: some View {
        HStack(spacing: 12) {
            Text("Leave at")
                .font(.rdSectionHeader)
                .foregroundStyle(Color.secondary)
            Spacer(minLength: 0)
            Button {
                isDeparturePickerPresented = true
            } label: {
                Text(leaveAtPillText)
                    .font(.rdRowName)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(pillBacking))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Leave at, \(leaveAtPillText)")
            .accessibilityHint("Double tap to choose departure time")
            .sheet(isPresented: $isDeparturePickerPresented) {
                DepartureTimePickerSheet(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
    }

    private var checkRouteButton: some View {
        Button(action: viewModel.checkRoute) {
            HStack(spacing: 8) {
                Image(systemName: "scooter")
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityHidden(true)
                Text("Check Route")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.checkRouteBlue))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Check Route")
        .accessibilityHint("Double tap to check the route and its rain forecast")
    }

    @ViewBuilder
    private var cardsArea: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 140)
        case .failed(let message):
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 140)
                .padding(.horizontal, 8)
        case .idle:
            Spacer(minLength: 0)
        case .loaded:
            if let plan = viewModel.routePlan, !plan.alternatives.isEmpty {
                routeCards(plan)
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    private func routeCards(_ plan: RoutePlan) -> some View {
        ScrollView(.vertical) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(plan.alternatives.enumerated()), id: \.element.id) { index, alternative in
                        RouteCard(
                            index: index,
                            alternative: alternative,
                            isSelected: alternative.id == plan.selectedRouteID,
                            onTap: {
                                if alternative.id == plan.selectedRouteID {
                                    detent = .large
                                    showsDetail = true
                                } else {
                                    viewModel.selectRoute(alternative.id)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var originValue: String {
        viewModel.origin?.name ?? "Set origin"
    }

    private var destinationValue: String {
        viewModel.destination?.name ?? ""
    }

    private var destinationSymbol: String {
        viewModel.destination?.categorySymbol ?? "mappin.circle.fill"
    }

    private var leaveAtPillText: String {
        guard let departureDate = viewModel.departureDate else { return "Now" }
        return departureTimeFormatter.string(from: departureDate)
    }

    private var pillBacking: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }

    private var rowBacking: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color.searchElement
    }

    private func presentSearch(_ target: SearchTarget) {
        searchViewModel.searchCoordinate = searchCoordinate
        activeSearch = target
    }

    private func handlePick(_ result: SearchResult, for target: SearchTarget) {
        switch target {
        case .origin:
            viewModel.updateOrigin(waypoint(from: result))
        case .stop:
            viewModel.addStop(waypoint(from: result))
        }
        activeSearch = nil
    }

    private func waypoint(from result: SearchResult) -> RouteWaypoint {
        RouteWaypoint(
            name: result.name,
            latitude: result.latitude,
            longitude: result.longitude,
            categorySymbol: result.categorySymbol
        )
    }
}

#Preview {
    TripPlannerSheet(
        viewModel: TripPlannerViewModel(
            directionsService: MockDirectionsService(),
            weatherService: MockWeatherService()
        ),
        searchService: MockDestinationSearchService(),
        searchCoordinate: CLLocationCoordinate2D(latitude: 52.229, longitude: 21.010)
    )
    .presentationDragIndicator(.visible)
}