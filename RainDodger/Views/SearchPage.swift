//
//  SearchPage.swift
//  RainDodger
//
//  Created by Jon on 06/09/26.
//

import SwiftUI

struct SearchPage: View {
    @Bindable var viewModel: SearchViewModel
    let onSelect: (SearchResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

            content
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.searchBackground)
        .onAppear {
            viewModel.onAppear()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                isFieldFocused = true
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.query) { _, query in
            viewModel.queryChanged(query)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                TextField("Your Destination…", text: $viewModel.query)
                    .font(.rdSearchField)
                    .focused($isFieldFocused)
                if !viewModel.query.isEmpty {
                    Button(action: viewModel.clearQuery) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.systemGray))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Clear search")
                }
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 28).fill(interactiveBackground))

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(interactiveBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close search")
        }
    }

    private var interactiveBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color.searchElement
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isQueryEmpty {
            if !viewModel.recents.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Text("Recent")
                            .font(.rdSectionHeader)
                            .foregroundStyle(Color.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        ForEach(viewModel.recents) { result in
                            rowButton(result)
                        }
                    }
                }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch viewModel.state {
                    case .searching:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    case .empty:
                        Text("No results")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    case .error(let message):
                        VStack(spacing: 12) {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                viewModel.queryChanged(viewModel.query)
                            }
                            .font(.headline)
                            .buttonStyle(.borderedProminent)
                            .frame(minWidth: 44, minHeight: 44)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.top, 48)
                    case .idle, .loaded:
                        ForEach(viewModel.results) { result in
                            rowButton(result)
                        }
                    }
                }
            }
        }
    }

    private func rowButton(_ result: SearchResult) -> some View {
        Button {
            viewModel.select(result)
            onSelect(result)
        } label: {
            SearchResultRow(result: result)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    SearchPage(
        viewModel: SearchViewModel(searchService: MockDestinationSearchService()),
        onSelect: { _ in }
    )
}
