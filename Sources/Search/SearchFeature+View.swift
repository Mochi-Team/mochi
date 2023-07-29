//
//  SearchFeature+View.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
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
        NavStack(
            store.scope(
                state: \.screens,
                action: Action.InternalAction.screens
            )
        ) {
            ZStack {
                WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
                    LoadableView(loadable: viewStore.items) { pagings in
                        Group {
                            if pagings.isEmpty {
                                Text("No results found.")
                            } else {
                                ScrollView(.vertical) {
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
                                                            store.viewAction.send(.didShowNextPageIndicator(nextPageId))
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
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } failedView: { _ in
                        Rectangle()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .padding()
                            .overlay(Text("Failed to fetch items"))
                    } loadingView: {
                        ProgressView()
                    } pendingView: {
                        Text("Type to search")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .topBar(title: "Search") {
                WithViewStore(store.viewAction, observe: \.selectedModule) { viewStore in
                    ModuleSelectionButton(module: viewStore.state?.module) {
                        store.viewAction.send(.didTapOpenModules)
                    }
                }
            } bottomAccessory: {
                WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)

                            TextField(
                                "Search for content...",
                                text: viewStore.$searchQuery
                                    .removeDuplicates()
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .regular))
                            .frame(maxWidth: .infinity)

                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.gray)
                                .opacity(viewStore.searchQuery.isEmpty ? 0.0 : 1.0)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewStore.send(.didClearQuery)
                                }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(.gray.opacity(0.1))
                        )
                        .frame(maxHeight: .infinity)

                        if !viewStore.searchFilters.isEmpty {
                            Button {
                                viewStore.send(.didTapFilterOptions)
                            } label: {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .overlay(
                                        Image(systemName: "line.horizontal.3.decrease")
                                            .font(.system(size: 18, weight: .bold))
                                            .contentShape(Rectangle())
                                            .aspectRatio(contentMode: .fit)
                                    )
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } destination: { store in
            SwitchStore(store) { state in
                switch state {
                case .playlistDetails:
                    CaseLet(
                        /SearchFeature.Screens.State.playlistDetails,
                        action: SearchFeature.Screens.Action.playlistDetails,
                        then: PlaylistDetailsFeature.View.init
                    )
                }
            }
        }
        .onAppear {
            store.viewAction.send(.didAppear)
        }
        .sheetPresentation(
            store: store.internalAction.scope(
                state: \.$moduleLists,
                action: Action.InternalAction.moduleLists
            ),
            content: ModuleListsFeature.View.init
        )
    }
}

// MARK: - SearchFeature.View.SearchStatus

extension SearchFeature.View {
    private enum SearchStatus {}
}

// MARK: - LazyView

@MainActor
private struct LazyView<Content: View>: View {
    let build: () -> Content

    @MainActor
    init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }

    @MainActor
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    @MainActor
    var body: some View {
        LazyVStack {
            build()
        }
    }
}

// MARK: - SearchFeatureView_Previews

struct SearchFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFeature.View(
            store: .init(
                initialState: .init(
                    searchQuery: "demo",
                    searchFilters: .init(),
                    selectedModule: nil,
                    items: .pending
                ),
                reducer: { EmptyReducer() }
            )
        )
    }
}
