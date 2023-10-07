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
        SheetDetent(
            isExpanded: $shouldExpand,
            initialHeight: searchBarSize - 8
        ) {
            ZStack {
                WithViewStore(store, observe: \.items) { viewStore in
                    LoadableView(loadable: viewStore.state) { pagings in
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
                        Rectangle()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .padding()
                            .overlay(Text("Failed to fetch items"))
                    } loadingView: {
                        ProgressView()
                    } pendingView: {
                        Text("Type to search")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 6)

                    WithViewStore(store, observe: \.`self`) { viewStore in
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search", text: viewStore.$query.removeDuplicates())
                                .textFieldStyle(.plain)
                                .focused($textFieldFocused)
                                .frame(maxWidth: .infinity)

                            ZStack {
                                if !viewStore.query.isEmpty {
                                    Image(systemName: "xmark.circle.fill")
                                        .onTapGesture {
                                            store.send(.view(.didTapClearQuery))
                                        }
                                }
                            }
                            .animation(.easeInOut, value: viewStore.query.isEmpty)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .style(
                                    withStroke: Color.gray.opacity(0.24),
                                    lineWidth: 1,
                                    fill: Color.gray.opacity(0.14)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
                .padding(.bottom, 10)
                .background(
                    RoundedCorners(topRadius: 16)
                        .style(
                            withStroke: Color.gray.opacity(0.2),
                            lineWidth: 1,
                            fill: .regularMaterial
                        )
                )
                .readSize { sizeInset in
                    searchBarSize = sizeInset.size.height
                    onSearchBarSizeChanged(sizeInset.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 0.1)
        .onAppear {
            store.send(.view(.didAppear))
        }
        .onChange(of: textFieldFocused) { focused in
            if focused { shouldExpand = true }
        }
    }
}

public extension SearchFeature.View {
    func onSearchBarSizeChanged(_ callback: @escaping (CGSize) -> Void) -> Self {
        var view = self
        view.onSearchBarSizeChanged = callback
        return view
    }
}

// MARK: - SearchFeature.View.SearchStatus

extension SearchFeature.View {
    private enum SearchStatus {}
}

// MARK: - SearchFeatureView_Previews

struct SearchFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFeature.View(
            store: .init(
                initialState: .init(
                    query: "demo",
                    filters: .init(),
                    items: .pending
                ),
                reducer: { EmptyReducer() }
            )
        )
    }
}
