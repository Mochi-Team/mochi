//
//  SearchFeature+View.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleLists
import NukeUI
import OrderedCollections
import PlaylistDetails
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - SearchFeature.View + View

extension SearchFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.`self`) { viewStore in
            VStack(alignment: .leading) {
                #if os(macOS)
                if viewStore.items.value?.isEmpty ?? true {
                    filters
                }
                #endif
                LoadableView(loadable: viewStore.items) { pagings in
                    if pagings.isEmpty {
                        Text("No results found.")
                    } else {
                        ScrollView(.vertical) {
                            #if os(macOS)
                            filters
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Items")
                                .font(.body.weight(.bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            #endif

                            LazyVGrid(
                                columns: .init(
                                    repeating: .init(alignment: .top),
                                    count: 3
                                ),
                                alignment: .leading
                            ) {
                                let allItems = pagings.values.flatMap { $0.value?.items ?? [] }
                                ForEach(allItems) { item in
                                    VStack(alignment: .leading) {
                                        FillAspectImage(url: item.posterImage)
                                            .aspectRatio(2 / 3, contentMode: .fit)
                                            .cornerRadius(12)

                                        Text(item.title ?? "Title Unavailable")
                                            .font(.footnote)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewStore.send(.didTapPlaylist(item))
                                    }
                                }
                            }
                            .padding(.horizontal)

                            if let lastPage = pagings.values.last {
                                LoadableView(loadable: lastPage) { page in
                                    LazyView {
                                        Spacer()
                                            .frame(height: 1)
                                            .onAppear {
                                                if let nextPageId = page.nextPage {
                                                    store.send(.view(.didShowNextPageIndicator(nextPageId)))
                                                }
                                            }
                                    }
                                } failedView: { _ in
                                    Text("Failed to retrieve content")
                                        .foregroundColor(.red)
                                } waitingView: {
                                    ProgressView()
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                } failedView: { _ in
                    Text("Failed to fetch itemss")
                } loadingView: {
                    ProgressView()
                } pendingView: {
                    Text("Type to search")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .bind(viewStore.$searchFieldFocused, to: self.$searchFieldFocused)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .topBar(
            backgroundStyle: .system,
            backCallback: {
                store.send(.view(.didTapBackButton))
            },
            leadingAccessory: {
                WithViewStore(store, observe: \.`self`) { viewStore in
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)

                                TextField("Search...", text: viewStore.$query.removeDuplicates())
                                    .textFieldStyle(.plain)
                                    .focused($searchFieldFocused)
                                    .frame(maxWidth: .infinity)
                                    .transition(.slide)
                                    .matchedGeometryEffect(id: "Search", in: searchAnimation)

                                ZStack {
                                    if !viewStore.query.isEmpty {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .onTapGesture {
                                                viewStore.send(.didTapClearQuery)
                                            }
                                    }
                                }
                                .animation(.easeInOut, value: viewStore.query.isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .style(
                                        withStroke: Color.gray.opacity(0.16),
                                        lineWidth: 1,
                                        fill: Color.gray.opacity(0.1)
                                    )
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 8)
            },
            trailingAccessory: EmptyView.init,
            bottomAccessory: { filters }
        )
        #elseif os(macOS)
        .navigationTitle("Search")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.view(.didTapBackButton))
                } label: {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .automatic) {
                WithViewStore(store, observe: \.`self`) { viewStore in
                    TextField("Search...", text: viewStore.$query.removeDuplicates())
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 200)
                }
            }
        }
        #endif
        .task {
            store.send(.view(.didAppear))
        }
    }
}

extension SearchFeature.View {
    private struct FilterView: View {
        @Environment(\.theme)
        var theme

        @Environment(\.colorScheme)
        var scheme

        let filter: SearchFilter
        let selectedOptions: [SearchFilter.Option]
        let tappedFilterOption: (SearchFilter.Option) -> Void

        var body: some View {
            Menu {
                ForEach(filter.options) { option in
                    Button {
                        tappedFilterOption(option)
                    } label: {
                        if selectedOptions[id: option.id] != nil {
                            Label(option.displayName.capitalized, systemImage: "checkmark")
                        } else {
                            Text(option.displayName.capitalized)
                        }
                    }
                }
            } label: {
                HStack {
                    if let option = selectedOptions.first, selectedOptions.count > 1 {
                        Text("\(filter.displayName.capitalized): \(option.displayName.capitalized) +\(selectedOptions.count - 1)")
                    } else if let option = selectedOptions.first {
                        Text("\(filter.displayName.capitalized): \(option.displayName.capitalized)")
                    } else {
                        Text(filter.displayName.capitalized)
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundColor(selectedOptions.isEmpty ? nil : .white)
                .lineLimit(1)
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().style(
                    withStroke: .gray.opacity(0.2),
                    fill: selectedOptions.isEmpty ? buttonBackgroundColor : selectedColor
                ))
            }
            .buttonStyle(.plain)
        }

        var selectedColor: Color { Theme.pastelGreen }
        var buttonBackgroundColor: Color { scheme == .dark ? .init(white: 0.2) : .init(white: 0.94) }
    }

    private struct FiltersState: Equatable {
        let isThereFilters: Bool
        let selectedFilters: [SearchFilter]
        let sortedAllFilters: [SearchFilter]

        init(_ state: SearchFeature.State) {
            self.isThereFilters = !state.allFilters.isEmpty
            self.selectedFilters = state.selectedFilters
            var sorted: [SearchFilter] = []

            for selected in state.selectedFilters {
                if let filter = state.allFilters.first(where: \.id == selected.id) {
                    sorted.append(filter)
                }
            }

            for filter in state.allFilters where !sorted.contains(where: \.id == filter.id) {
                sorted.append(filter)
            }

            self.sortedAllFilters = sorted
        }
    }

    var filters: some View {
        WithViewStore(store, observe: FiltersState.init) { viewStore in
            VStack(alignment: .leading) {
                if viewStore.isThereFilters {
                    #if os(macOS)
                    Text("Filters")
                        .font(.body.weight(.bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    #endif

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if !viewStore.selectedFilters.isEmpty {
                                Menu {
                                    Section {
                                        Button(role: .destructive) {
                                            viewStore.send(.didTapClearFilters)
                                        } label: {
                                            Text("Clear all filters")
                                                .foregroundColor(.red)
                                        }
                                    } header: {
                                        Text("\(viewStore.selectedFilters.count) filters applied")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "line.3.horizontal.decrease")
                                        Text(viewStore.selectedFilters.count.description)
                                    }
                                    .font(.footnote)
                                    .padding(8)
                                    .foregroundColor(.white)
                                    .background(
                                        Capsule()
                                            .style(
                                                withStroke: .gray.opacity(0.2),
                                                fill: Theme.pastelGreen
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                                .frame(maxHeight: .infinity)
                            }

                            ForEach(viewStore.sortedAllFilters) { filter in
                                FilterView(
                                    filter: filter,
                                    selectedOptions: viewStore.selectedFilters[id: filter.id]?.options ?? []
                                ) { option in
                                    viewStore.send(.didTapFilter(filter, option))
                                }
                                .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        #if os(macOS)
                        .padding(.horizontal)
                        #endif
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewStore.selectedFilters.count)
            #if os(macOS)
            .padding(.top)
            #endif
        }
    }
}

// MARK: - SearchFeatureView_Previews

#Preview {
    SearchFeature.View(
        store: .init(
            initialState: .init(
                query: "demo",
                selectedFilters: .init([
                    SearchFilter(
                        id: .init("1"),
                        displayName: "Filter",
                        multiselect: true,
                        required: false,
                        options: [.init(id: .init("1"), displayName: "Option 1")]
                    )
                ]),
                allFilters: .init([
                    SearchFilter(
                        id: .init("1"),
                        displayName: "Filter",
                        multiselect: true,
                        required: false,
                        options: [.init(id: .init("1"), displayName: "Option 1")]
                    )
                ]),
                items: .pending
            ),
            reducer: { EmptyReducer() }
        ),
        namespace: Namespace().wrappedValue
    )
    .themeable()
}
