//
//  DestinationSearchService.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import Foundation
import CoreLocation
import MapKit
import SwiftData

protocol DestinationSearchService: AnyObject {
    func search(query: String, coordinate: CLLocationCoordinate2D?) async throws -> [SearchResult]
    func recentDestinations() async -> [SearchResult]
    func saveRecent(_ result: SearchResult) async
}

@MainActor
final class LiveDestinationSearchService: DestinationSearchService {
    private let modelContext: ModelContext
    private let recentLimit = 10

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func search(query: String, coordinate: CLLocationCoordinate2D?) async throws -> [SearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map(mapItemToResult)
    }

    func recentDestinations() async -> [SearchResult] {
        let descriptor = FetchDescriptor<RecentDestination>(
            sortBy: [SortDescriptor(\RecentDestination.savedAt, order: .reverse)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        return Array(items.prefix(recentLimit)).map(\.searchResult)
    }

    func saveRecent(_ result: SearchResult) async {
        let predicate = #Predicate<RecentDestination> {
            $0.name == result.name && $0.latitude == result.latitude && $0.longitude == result.longitude
        }
        let existing = try? modelContext.fetch(FetchDescriptor(predicate: predicate)).first
        if let existing {
            existing.savedAt = .now
        } else {
            modelContext.insert(RecentDestination(searchResult: result))
        }
        try? modelContext.save()
        trimRecents()
    }

    private func trimRecents() {
        let descriptor = FetchDescriptor<RecentDestination>(
            sortBy: [SortDescriptor(\RecentDestination.savedAt, order: .reverse)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for item in items.dropFirst(recentLimit) {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func mapItemToResult(_ item: MKMapItem) -> SearchResult {
        let location = item.location
        let name = item.name ?? ""
        let street = item.address?.shortAddress ?? item.address?.fullAddress ?? ""
        return SearchResult(
            id: UUID(),
            name: name,
            street: street,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            categorySymbol: categorySymbol(for: item.pointOfInterestCategory)
        )
    }

    private func categorySymbol(for category: MKPointOfInterestCategory?) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bakery: return "takeoutbag.and.cup.and.straw.fill"
        case .hotel: return "bed.double"
        case .gasStation: return "fuelpump"
        case .foodMarket, .store: return "cart.fill"
        case .airport: return "airplane"
        case .publicTransport: return "bus.fill"
        case .park: return "tree.fill"
        case .beach: return "beach.umbrella.fill"
        case .bank, .atm: return "banknote.fill"
        case .hospital: return "cross.case.fill"
        case .pharmacy: return "pills.fill"
        case .police: return "shield.fill"
        case .fireStation: return "flame.fill"
        case .school, .university: return "graduationcap.fill"
        case .library: return "books.vertical.fill"
        case .museum, .theater: return "building.columns.fill"
        case .movieTheater: return "film.fill"
        case .nightlife, .winery, .brewery: return "wineglass.fill"
        case .zoo: return "pawprint.fill"
        case .marina: return "sailboat.fill"
        case .amusementPark: return "ferriswheel"
        case .aquarium: return "fish.fill"
        case .campground: return "tent.fill"
        case .carRental, .parking, .evCharger: return "car.fill"
        case .postOffice: return "envelope.fill"
        case .laundry: return "washer.fill"
        default: return "mappin"
        }
    }
}

@MainActor
final class MockDestinationSearchService: DestinationSearchService {
    private var recents: [SearchResult] = []
    private let catalog: [SearchResult]

    init() {
        catalog = [
            SearchResult(id: UUID(), name: "Restauracja Stary Dom", street: "ul. Nowogrodzka 5", latitude: 52.2290, longitude: 21.0100, categorySymbol: "fork.knife"),
            SearchResult(id: UUID(), name: "Café Nero", street: "ul. Marszałkowska 10", latitude: 52.2300, longitude: 21.0140, categorySymbol: "cup.and.saucer"),
            SearchResult(id: UUID(), name: "Hotel Bristol", street: "ul. Krakowskie Przedmieście 42", latitude: 52.2420, longitude: 21.0150, categorySymbol: "bed.double"),
            SearchResult(id: UUID(), name: "Orlen", street: "al. Jerozolimskie 100", latitude: 52.2260, longitude: 21.0080, categorySymbol: "fuelpump"),
            SearchResult(id: UUID(), name: "Lotnisko Chopina", street: "ul. Żwirki i Wigury 1", latitude: 52.1660, longitude: 20.9680, categorySymbol: "airplane"),
        ]
    }

    func search(query: String, coordinate: CLLocationCoordinate2D?) async throws -> [SearchResult] {
        try? await Task.sleep(for: .milliseconds(150))
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return catalog.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) || $0.street.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func recentDestinations() async -> [SearchResult] {
        recents
    }

    func saveRecent(_ result: SearchResult) async {
        recents.removeAll { $0.id == result.id }
        recents.insert(result, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
    }
}
