//
//  DiscoverFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ModuleLists
import NukeUI
import PlaylistDetails
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension DiscoverFeature.View: View {
    @MainActor
    public var body: some View {
        NavStack(
            store.internalAction.scope(
                state: \.screens,
                action: Action.InternalAction.screens
            )
        ) {
            WithViewStore(store, observe: \.listings) { viewStore in
                ZStack {
                    LoadableView(loadable: viewStore.state) { listings in
                        Group {
                            if listings.isEmpty {
                                VStack(spacing: 12) {
                                    Spacer()

                                    Image(systemName: "questionmark.app.dashed")
                                        .font(.largeTitle)

                                    Text("No listings available for this module.")
                                        .font(.subheadline.bold())
                                    Spacer()
                                }
                            } else {
                                buildListingsView(listings)
                            }
                        }
                        .transition(.opacity)
                    } failedView: { error in
                        // TODO: Add error state depending on module or system fetching
                        VStack(spacing: 12) {
                            Spacer()

                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error.description)
                                .font(.body.weight(.semibold))

                            Spacer()
                        }
                        .transition(.opacity)
                    } waitingView: {
                        let placeholders: [Playlist] = [
                            .init(id: "placeholder 1", type: .video),
                            .init(id: "placeholder 2", type: .video),
                            .init(id: "placeholder 3", type: .video),
                            .init(id: "placeholder 4", type: .video),
                            .init(id: "placeholder 5", type: .video),
                            .init(id: "placeholder 6", type: .video),
                            .init(id: "placeholder 7", type: .video),
                            .init(id: "placeholder 8", type: .video),
                            .init(id: "placeholder 9", type: .video),
                            .init(id: "placeholder 10", type: .video)
                        ]
                        buildListingsView(
                            [
                                .init(
                                    title: "placeholder",
                                    type: .featured,
                                    paging: .init(
                                        items: [
                                            .init(id: "placeholder 1", type: .video)
                                        ],
                                        currentPage: "demo-1"
                                    )
                                ),
                                .init(
                                    title: "placeholder title",
                                    type: .default,
                                    paging: .init(
                                        items: placeholders,
                                        currentPage: "demo-1"
                                    )
                                ),
                                .init(
                                    title: "placeholder title 2",
                                    type: .rank,
                                    paging: .init(
                                        items: placeholders,
                                        currentPage: "demo-1"
                                    )
                                )
                            ]
                        )
                        .shimmering()
                        .disabled(true)
                        .transition(.opacity)
                    }
                }
                .edgesIgnoringSafeArea(viewStore.state.shouldIgnoreTop ? .top : .init())
                .animation(.easeInOut(duration: 0.25), value: viewStore.state.didFinish)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .safeAreaInset(edge: .top) {
                WithViewStore(store, observe: \.listings.shouldIgnoreTop) { viewStore in
                    // swiftlint:disable trailing_closure
                    TopBarView(
                        backgroundStyle: viewStore.state ? .clear : .system,
                        trailingAccessory: {
                            WithViewStore(store.viewAction, observe: \.selectedRepoModule) { viewStore in
                                ModuleSelectionButton(module: viewStore.state?.module) {
                                    viewStore.send(.didTapOpenModules)
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                ViewStore(store.viewAction.stateless).send(.didAppear)
            }
        } destination: { store in
            SwitchStore(store) { state in
                switch state {
                case .playlistDetails:
                    CaseLet(
                        /DiscoverFeature.Screens.State.playlistDetails,
                         action: DiscoverFeature.Screens.Action.playlistDetails,
                         then: PlaylistDetailsFeature.View.init
                    )
                }
            }
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

extension DiscoverFeature.View {
    @MainActor
    func buildListingsView(_ listings: [DiscoverListing]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                ForEach(listings, id: \.title) { listing in
                    switch listing.type {
                    case .default:
                        rowListing(listing)
                    case .rank:
                        rankListing(listing)
                    case .featured:
                        featuredListing(listing)
                    }
                }
            }
        }
    }
}

extension DiscoverFeature.View {
    @MainActor
    func rowListing(_ listing: DiscoverListing) -> some View {
        LazyVStack(alignment: .leading) {
            HStack {
                Text(listing.title)
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                if listing.paging.nextPage != nil {
                    Button {
                    } label: {
                        Text("Show All")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                            .opacity(listing.items.isEmpty ? 0 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if listing.items.isEmpty {
                Color.gray.opacity(0.2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .overlay(
                        Text("No content available")
                            .font(.callout.weight(.medium))
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(listing.items) { playlist in
                            VStack(alignment: .leading, spacing: 6) {
                                LazyImage(
                                    url: playlist.posterImage,
                                    transaction: .init(animation: .easeInOut(duration: 0.16))
                                ) { state in
                                    if let image = state.image {
                                        image.resizable()
                                    } else {
                                        Color.gray
                                            .opacity(0.35)
                                    }
                                }
                                .aspectRatio(5 / 7, contentMode: .fit)
                                .cornerRadius(12)

                                Text(playlist.title ?? "No Title")
                                    .lineLimit(3)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 124)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                ViewStore(store.viewAction.stateless)
                                    .send(.didTapPlaylist(playlist))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    func rankListing(_ listing: DiscoverListing) -> some View {
        LazyVStack(alignment: .leading) {
            HStack {
                Text(listing.title)
                    .font(.title3.weight(.semibold))

                Spacer()

                if listing.paging.nextPage != nil {
                    Button {
                    } label: {
                        Text("Show All")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.gray)
                            .opacity(listing.items.isEmpty ? 0 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if listing.items.isEmpty {
                Color.gray.opacity(0.2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .overlay(
                        Text("No content available")
                            .font(.callout.weight(.medium))
                    )
            } else {
                let rowCount = 3
                let sections: Int = (listing.items.count - 1) / rowCount
                SnapScroll(
                    alignment: .top,
                    spacing: 20,
                    edgeInsets: .init(trailing: 40),
                    items: Array(0 ... sections)
                ) { col in
                    let start = col * rowCount
                    let end = start + min(rowCount, listing.items.count - start)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(start ..< end, id: \.self) { idx in
                            let playlist = listing.items[idx]
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(idx + 1)")
                                    .font(.body.monospacedDigit().weight(.bold))

                                LazyImage(
                                    url: playlist.posterImage,
                                    transaction: .init(animation: .easeInOut(duration: 0.16))
                                ) { state in
                                    if let image = state.image {
                                        image.resizable()
                                    } else {
                                        Color.gray
                                            .opacity(0.35)
                                    }
                                }
                                .aspectRatio(5 / 7, contentMode: .fill)
                                .frame(width: 64)
                                .cornerRadius(12)

                                Text(playlist.title ?? "No Title")
                                    .lineLimit(3)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                ViewStore(store.viewAction.stateless)
                                    .send(.didTapPlaylist(playlist))
                            }

                            if idx < (end - 1) {
                                Divider()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    @ViewBuilder
    func featuredListing(_ listing: DiscoverListing) -> some View {
        if !listing.items.isEmpty {
            TabView {
                ForEach(listing.items, id: \.id) { playlist in
                    LazyImage(
                        url: playlist.posterImage ?? playlist.bannerImage,
                        transaction: .init(animation: .easeInOut(duration: 0.16))
                    ) { state in
                        if let image = state.image {
                            image.resizable()
                        } else {
                            Color.gray
                                .opacity(0.35)
                        }
                    }
                    .onTapGesture {
                        ViewStore(store.viewAction.stateless).send(.didTapPlaylist(playlist))
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .aspectRatio(5 / 7, contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
    }
}

private extension Loadable<[DiscoverListing], DiscoverFeature.Error> {
    var shouldIgnoreTop: Bool {
        switch self {
        case .pending, .loading:
            return true
        case .loaded(let t):
            return t.contains(where: \.type == .featured)
        case .failed:
            return false
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverFeature.View(
            store: .init(
                initialState: .init(
                    listings: .loading
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
