//
//  DiscoverFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import ModuleLists
import Nuke
import NukeUI
import PlaylistDetails
import Search
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - DiscoverFeature.View + View

extension DiscoverFeature.View: View {
    @MainActor
    public var body: some View {
        NavStack(
            store.scope(
                state: \.screens,
                action: Action.InternalAction.screens
            )
        ) {
            ZStack(alignment: .bottom) {
                WithViewStore(store, observe: \.selected) { viewStore in
                    ZStack {
                        switch viewStore.state {
                        case .home:
                            // TODO: Create home listing
                            VStack {
                                Spacer()
                                Text("Coming soon!")
                                Spacer()
                            }
                        case let .module(moduleState):
                            buildModuleView(moduleState: moduleState)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewStore.state)
                    #if os(iOS)
                    .safeAreaInset(edge: .top) {
                        TopBarView(
                            backgroundStyle: .gradient(),
                            leadingAccessory: {
                                Button {
                                    viewStore.send(.didTapOpenModules)
                                } label: {
                                    HStack(spacing: 8) {
                                        if let url = viewStore.icon {
                                            LazyImage(url: url) { state in
                                                if let image = state.image {
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 22, height: 22)
                                                } else {
                                                    EmptyView()
                                                }
                                            }
                                            .transition(.opacity)
                                        }

                                        Text(viewStore.title)
                                        Image(systemName: "chevron.down")
                                            .font(.body.weight(.bold))
                                        Spacer()
                                    }
                                    .font(.title.bold())
                                    .contentShape(Rectangle())
                                    .scaleEffect(1.0)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: viewStore.icon)
                                }
                                .buttonStyle(.plain)
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                    #elseif os(macOS)
                    .navigationTitle("")
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Button {
                                viewStore.send(.didTapOpenModules)
                            } label: {
                                HStack(spacing: 8) {
                                    if let url = viewStore.icon {
                                        LazyImage(url: url) { state in
                                            if let image = state.image {
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 22, height: 22)
                                            } else {
                                                EmptyView()
                                            }
                                        }
                                        .transition(.opacity)
                                    }

                                    Text(viewStore.title)
                                        .font(.title3.bold())

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 1).weight(.semibold))
                                }
                                .contentShape(Rectangle())
                                .scaleEffect(1.0)
                                .transition(.opacity)
                                .animation(.easeInOut, value: viewStore.icon)
                            }
                            .buttonStyle(.bordered)
                        }

                        ToolbarItem(placement: .automatic) {
                            WithViewStore(
                                store.scope(
                                    state: \.search,
                                    action: Action.InternalAction.search
                                ),
                                observe: \.`self`
                            ) { viewStore in
                                TextField("Search for Content", text: viewStore.$query)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(minWidth: 200)
                            }
                        }
                    }
                    #endif
                    .safeAreaInset(edge: .bottom) {
                        Spacer()
                            .frame(height: searchBarSize.height)
                    }
                }
                .zIndex(1)

                SearchFeature.View(
                    store: store.scope(
                        state: \.search,
                        action: Action.InternalAction.search
                    )
                )
                .onSearchBarSizeChanged { size in
                    searchBarSize = size
                }
                .zIndex(2)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .onAppear { store.send(.view(.didAppear)) }
            .moduleListsSheet(
                store.scope(
                    state: \.$moduleLists,
                    action: { .internal(.moduleLists($0)) }
                )
            )
            .safeInset(from: \.bottomNavigation, edge: .bottom)
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
            .safeInset(from: \.bottomNavigation, edge: .bottom, alignment: .center)
        }
    }
}

extension DiscoverFeature.View {
    @MainActor
    func buildModuleView(moduleState: DiscoverFeature.Section.ModuleListingState) -> some View {
        LoadableView(loadable: moduleState.listings) { listings in
            Group {
                if listings.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("Listings Empty")
                            .font(.title2.weight(.medium))
                        Text("There are no listings for this module.")
                        Spacer()
                    }
                    .foregroundColor(.gray)
                } else {
                    buildListingsView(listings)
                }
            }
            .transition(.opacity)
        } failedView: { _ in
            VStack(spacing: 12) {
                Spacer()

                Text("Module Error")
                    .font(.title2.weight(.medium))
                Text("There was an error fetching content.")
                Button {
                    // TODO: Allow retrying
                } label: {
                    Text("Retry")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.gray.opacity(0.25))
                        }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .transition(.opacity)
        } waitingView: {
            let placeholders: [Playlist] = (0..<10).map { .placeholder($0) }

            buildListingsView(
                [
                    .init(
                        id: "0",
                        title: "placeholder title 1",
                        type: .featured,
                        paging: .init(
                            id: "demo-1",
                            items: placeholders
                        )
                    ),
                    .init(
                        id: "1",
                        title: "placeholder title 2",
                        type: .default,
                        paging: .init(
                            id: "demo-1",
                            items: placeholders
                        )
                    ),
                    .init(
                        id: "2",
                        title: "placeholder title 3",
                        type: .rank,
                        paging: .init(
                            id: "demo-1",
                            items: placeholders
                        )
                    ),
                    .init(
                        id: "3",
                        title: "placeholder title 4",
                        type: .default,
                        paging: .init(
                            id: "demo-1",
                            items: placeholders
                        )
                    )
                ]
            )
            .shimmering()
            .disabled(true)
            .transition(.opacity)
        }
    }
}

extension DiscoverFeature.View {
    @MainActor
    func buildListingsView(_ listings: [DiscoverListing]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                ForEach(listings, id: \.id) { listing in
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
                    Button {} label: {
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
                                store.send(.view(.didTapPlaylist(playlist)))
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
                    Button {} label: {
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
                    items: Array(0...sections)
                ) { col in
                    let start = col * rowCount
                    let end = start + min(rowCount, listing.items.count - start)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(start..<end, id: \.self) { idx in
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
                                store.send(.view(.didTapPlaylist(playlist)))
                            }

                            if idx < (end - 1) {
                                Divider()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .aspectRatio(1.5, contentMode: .fill)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    @ViewBuilder
    func featuredListing(_ listing: DiscoverListing) -> some View {
        VStack {
            HStack {
                Text(listing.title)
                    .font(.title3.weight(.semibold))

                Spacer()

                if listing.paging.nextPage != nil {
                    Button {} label: {
                        Text("Show All")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.gray)
                            .opacity(listing.items.isEmpty ? 0 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // TODO: Make size based on listing's size type
            SnapScroll(
                alignment: .center,
                spacing: 8,
                edgeInsets: .init(leading: 8, trailing: 8),
                items: listing.items
            ) { playlist in
                ZStack(alignment: .bottom) {
                    FillAspectImage(url: playlist.bannerImage ?? playlist.posterImage)
                        .overlay {
                            LinearGradient(
                                gradient: .init(
                                    colors: [
                                        .black.opacity(0),
                                        .black.opacity(0.4)
                                    ],
                                    easing: .easeIn
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                    Text(playlist.title ?? "No Title")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .cornerRadius(12)
                .onTapGesture {
                    store.send(.view(.didTapPlaylist(playlist)))
                }
            }
            .aspectRatio(6 / 7, contentMode: .fill)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - DiscoverView_Previews

#Preview {
    DiscoverFeature.View(
        store: .init(
            initialState: .init(selected: .home()),
            reducer: { EmptyReducer() }
        )
    )
}
