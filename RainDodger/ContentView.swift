//
//  ContentView.swift
//  RainDodger
//
//  Created by Jon on 25/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MapViewModel(locationService: LiveLocationService())

    var body: some View {
        MapScreenView(viewModel: viewModel)
    }
}

#Preview {
    MapScreenView(viewModel: MapViewModel(locationService: MockLocationService()))
}
