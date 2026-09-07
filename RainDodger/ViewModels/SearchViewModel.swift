//
//  SearchViewModel.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    enum SearchState: Equatable {
        case idle
        case searching
        case loaded
        case empty
        case error(String)
    }

    var query = ""
    private(set) var results: [SearchResult] = []
    private(set) var recents: [SearchResult] = []
    private(set) var state: SearchState = .idle
    var searchCoordinate: CLLocationCoordinate2D?

    var isQueryEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let searchService: DestinationSearchService
    private var searchTask: Task<Void, Never>?

    init(searchService: DestinationSearchService) {
        self.searchService = searchService
    }

    func onAppear() {
        query = ""
        results = []
        state = .idle
        cancelSearch()
        Task { await loadRecents() }
    }

    func onDisappear() {
        cancelSearch()
    }

    func queryChanged(_ value: String) {
        cancelSearch()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            state = .idle
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard let self, !Task.isCancelled else { return }
            await self.runSearch(trimmed)
        }
    }

    func clearQuery() {
        query = ""
        cancelSearch()
        results = []
        state = .idle
    }

    func select(_ result: SearchResult) {
        Task { [weak self] in
            guard let self else { return }
            await self.searchService.saveRecent(result)
            await self.loadRecents()
        }
    }

    private func runSearch(_ query: String) async {
        state = .searching
        do {
            let found = try await searchService.search(query: query, coordinate: searchCoordinate)
            guard !Task.isCancelled else { return }
            results = found
            state = found.isEmpty ? .empty : .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }

    private func loadRecents() async {
        recents = await searchService.recentDestinations()
    }

    private func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
