//
//  MapScreenView.swift
//  RainDodger
//
//  Created by Jon on 04/09/26.
//

import SwiftUI
import MapKit

struct MapScreenView: View {
    @Bindable var viewModel: MapViewModel
    let searchService: DestinationSearchService

    @State private var searchViewModel: SearchViewModel
    @State private var tripPlanner: TripPlannerViewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: MapViewModel, searchService: DestinationSearchService, directionsService: DirectionsService) {
        self.viewModel = viewModel
        self.searchService = searchService
        _searchViewModel = State(initialValue: SearchViewModel(searchService: searchService))
        _tripPlanner = State(initialValue: TripPlannerViewModel(directionsService: directionsService))
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            ZStack {
                map

                if viewModel.authorizationState == .denied {
                    LocationPermissionOverlay(onOpenSettings: openSettings)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 12) {
//                    CompassControl(
//                        heading: viewModel.heading,
//                        onTap: viewModel.resetNorthAndRecenter
//                    )
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
                    if shouldShowRoutePill {
                        RouteSummaryPill(viewModel: tripPlanner) {
                            viewModel.isTripSheetPresented = true
                        }
                    } else {
                        DestinationSearchField(onTap: viewModel.searchFieldTapped)
                    }
                }
                .padding(.horizontal, isLandscape ? 0 : 16)
                .padding(.bottom, isLandscape ? 8 : 12)
            }
            .sheet(isPresented: $viewModel.isSearchPresented) {
                SearchPage(viewModel: searchViewModel, onSelect: selectDestination)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.isTripSheetPresented) {
                TripPlannerSheet(
                    viewModel: tripPlanner,
                    searchService: searchService,
                    searchCoordinate: viewModel.currentCoordinate
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onChange(of: viewModel.isSearchPresented) { _, presented in
            if presented {
                searchViewModel.searchCoordinate = viewModel.currentCoordinate
            }
        }
        .onChange(of: viewModel.cameraIntent) { _, intent in
            guard let intent else { return }
            switch intent {
            case .recenter, .resetNorthAndRecenter:
                withAnimation {
                    cameraPosition = .userLocation(followsHeading: false, fallback: .automatic)
                }
            case .focusDestination(let coordinate):
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
            viewModel.consumeCameraIntent()
        }
        .onChange(of: tripPlanner.routePlan?.selectedRouteID) { _, _ in
            fitCameraToRoute()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshAuthorizationState()
            }
        }
    }

    private var shouldShowRoutePill: Bool {
        !viewModel.isTripSheetPresented
            && tripPlanner.state != .idle
            && !isTripPlanFailed
    }

    private var isTripPlanFailed: Bool {
        if case .failed = tripPlanner.state { return true }
        return false
    }

    private var map: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                UserAnnotation()
                if let plan = tripPlanner.routePlan, !isTripPlanFailed {
                    ForEach(plan.alternatives) { alternative in
                        let isSelected = alternative.id == plan.selectedRouteID
                        MapPolyline(alternative.polyline)
                            .stroke(
                                isSelected ? Color.blue : Color.blue.opacity(0.4),
                                lineWidth: isSelected ? 6 : 2
                            )
                    }
                    if let origin = plan.origin, !isCurrentLocation(origin) {
                        Marker(origin.name, coordinate: origin.coordinate)
                    }
                    if let stop = plan.stop {
                        Marker(stop.name, coordinate: stop.coordinate)
                    }
                    Marker(plan.destination.name, coordinate: plan.destination.coordinate)
                } else if let destination = viewModel.selectedDestination {
                    Marker(destination.name, coordinate: destination.coordinate)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .overlay {
                mapBadges(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func mapBadges(proxy: MapProxy) -> some View {
        if let plan = tripPlanner.routePlan, !isTripPlanFailed,
           let selected = plan.alternatives.first(where: { $0.id == plan.selectedRouteID }) ?? plan.alternatives.first {
            if let destinationPoint = proxy.convert(plan.destination.coordinate, to: .local) {
                destinationETABadge(selected)
                    .position(x: destinationPoint.x, y: destinationPoint.y - 42)
            }
            if let midpoint = routeMidpoint(selected),
               let badgePoint = proxy.convert(midpoint, to: .local) {
                fastestBadge(selected)
                    .position(x: badgePoint.x, y: badgePoint.y - 26)
            }
        }
    }

    private func destinationETABadge(_ route: RouteAlternative) -> some View {
        Text("\(Int(route.travelTime / 60)) min")
            .font(.headline)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Capsule().fill(Color(.systemBackground)))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .accessibilityHidden(true)
    }

    private func fastestBadge(_ route: RouteAlternative) -> some View {
        Text("\(Int(route.travelTime / 60)) min Fastest")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Capsule().fill(Color.checkRouteBlue))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .accessibilityHidden(true)
    }

    private func routeMidpoint(_ route: RouteAlternative) -> CLLocationCoordinate2D? {
        guard !route.coordinatePoints.isEmpty else { return nil }
        return route.coordinatePoints[route.coordinatePoints.count / 2]
    }

    private func selectDestination(_ result: SearchResult) {
        viewModel.selectDestination(result)
        if let coordinate = viewModel.currentCoordinate {
            tripPlanner.setOriginFromCurrentLocation(coordinate)
        }
        tripPlanner.updateDestination(
            RouteWaypoint(
                name: result.name,
                latitude: result.latitude,
                longitude: result.longitude,
                categorySymbol: result.categorySymbol
            )
        )
    }

    private func isCurrentLocation(_ waypoint: RouteWaypoint) -> Bool {
        guard let current = viewModel.currentCoordinate else { return false }
        return waypoint.latitude == current.latitude && waypoint.longitude == current.longitude
    }

    private func fitCameraToRoute() {
        guard let plan = tripPlanner.routePlan else { return }
        guard let selected = plan.alternatives.first(where: { $0.id == plan.selectedRouteID }) ?? plan.alternatives.first else { return }
        var points = selected.coordinatePoints
        if let origin = plan.origin { points.append(origin.coordinate) }
        if let stop = plan.stop { points.append(stop.coordinate) }
        points.append(plan.destination.coordinate)
        let region = fittingRegion(for: points)
        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .region(region)
            }
        }
    }

    private func fittingRegion(for points: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for point in points.dropFirst() {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        let paddingFactor = 1.6
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * paddingFactor, 0.01),
                longitudeDelta: max((maxLon - minLon) * paddingFactor, 0.01)
            )
        )
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
    MapScreenView(
        viewModel: MapViewModel(locationService: MockLocationService()),
        searchService: MockDestinationSearchService(),
        directionsService: MockDirectionsService()
    )
}
