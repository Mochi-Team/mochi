//
//  SearchFeature+View.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import NukeUI
import PlaylistDetails
import Styling
import SwiftUI
import ViewComponents

extension SearchFeature.View: View {
    @MainActor
    public var body: some View {
        NavStack(
            store.scope(
                state: \.screens,
                action: Action.InternalAction.screens
            )
        ) {
            WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        LoadableView(loadable: viewStore.items) { paging in
                            LazyVGrid(
                                columns: .init(
                                    repeating: .init(alignment: .top),
                                    count: 3
                                ),
                                alignment: .leading
                            ) {
                                ForEach(paging.items) { item in
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
                        ModuleSelectionButton(module: viewStore.state?.module.manifest) {
                            ViewStore(store.viewAction.stateless)
                                .send(.didTapOpenModules)
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
                                    text: viewStore.binding(\.$searchQuery.query)
                                        .removeDuplicates()
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .regular))
                                .frame(maxWidth: .infinity)

                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.gray)
                                    .opacity(viewStore.searchQuery.query.isEmpty ? 0.0 : 1.0)
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
                .onAppear {
                    ViewStore(store.viewAction.stateless).send(.didAppear)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } content: { store in
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFeature.View(
            store: .init(
                initialState: .init(
                    searchQuery: .init(query: "demo"),
                    searchFilters: [
                        .init(
                            id: "filter-one",
                            displayName: "hehehe",
                            multiSelect: false,
                            required: true,
                            options: []
                        )
                    ],
                    selectedModule: nil,
                    items: .loaded(
                        .init(
                            items: [
                                .init(
                                    id: "playlist",
                                    title: "Demo 1",
                                    type: .video
                                )
                            ],
                            currentPage: "1",
                            nextPage: nil
                        )
                    )
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
