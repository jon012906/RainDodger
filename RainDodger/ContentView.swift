//
//  ContentView.swift
//  RainDodger
//
//  Created by Jon on 25/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel(locationService: LiveLocationService())

    var body: some View {
        MapScreenView(
            viewModel: viewModel,
            searchService: LiveDestinationSearchService(modelContext: modelContext)
        )
    }
}

#Preview {
    MapScreenView(
        viewModel: MapViewModel(locationService: MockLocationService()),
        searchService: MockDestinationSearchService()
    )
}
