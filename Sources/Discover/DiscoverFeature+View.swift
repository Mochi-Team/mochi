//
//  DiscoverFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension DiscoverFeature.View: View {
    @MainActor
    public var body: some View {
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
                    buildListingsView(
                        [
                            .init(
                                title: "placeholder",
                                type: .featured,
                                paging: .init(
                                    items: [
                                        .init(id: "placeholder 1", meta: .video)
                                    ],
                                    currentPage: "demo-1"
                                )
                            ),
                            .init(
                                title: "placeholder title",
                                type: .default,
                                paging: .init(
                                    items: [
                                        .init(id: "placeholder 1", meta: .video),
                                        .init(id: "placeholder 2", meta: .video),
                                        .init(id: "placeholder 3", meta: .video),
                                        .init(id: "placeholder 4", meta: .video),
                                        .init(id: "placeholder 5", meta: .video),
                                        .init(id: "placeholder 6", meta: .video),
                                        .init(id: "placeholder 7", meta: .video),
                                        .init(id: "placeholder 8", meta: .video),
                                        .init(id: "placeholder 9", meta: .video),
                                        .init(id: "placeholder 10", meta: .video)
                                    ],
                                    currentPage: "demo-1"
                                )
                            ),
                            .init(
                                title: "placeholder title 2",
                                type: .rank,
                                paging: .init(
                                    items: [
                                        .init(id: "placeholder 1", meta: .video),
                                        .init(id: "placeholder 2", meta: .video),
                                        .init(id: "placeholder 3", meta: .video),
                                        .init(id: "placeholder 4", meta: .video),
                                        .init(id: "placeholder 5", meta: .video),
                                        .init(id: "placeholder 6", meta: .video),
                                        .init(id: "placeholder 7", meta: .video),
                                        .init(id: "placeholder 8", meta: .video),
                                        .init(id: "placeholder 9", meta: .video),
                                        .init(id: "placeholder 10", meta: .video)
                                    ],
                                    currentPage: "demo-1"
                                )
                            )
                        ]
                    )
                    .redacted(reason: .placeholder)
                    .shimmering()
                    .disabled(true)
                    .transition(.opacity)
                }
            }
            .edgesIgnoringSafeArea(viewStore.state.shouldIgnoreTop ? .top : .init())
            .animation(.easeInOut(duration: 0.25), value: viewStore.state.finished)
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
                        WithViewStore(store.viewAction, observe: \.selectedModule) { viewStore in
                            ModuleSelectionButton(module: viewStore.state) {
                                viewStore.send(.didTapOpenModules)
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(maxWidth: .infinity)
                .frame(height: bottomNavigationSize.height)
        }
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
    }
}

extension DiscoverFeature.View {
    @MainActor
    func buildListingsView(_ listings: [DiscoverListing]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
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

                Text("Show All")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .opacity(listing.items.isEmpty ? 0 : 1.0)
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
                        ForEach(listing.items) { media in
                            VStack(alignment: .leading, spacing: 6) {
                                LazyImage(url: media.posterImage) { state in
                                    if let image = state.image {
                                        image.resizable()
                                    } else {
                                        Color.gray
                                            .opacity(0.35)
                                    }
                                }
                                .aspectRatio(5 / 7, contentMode: .fit)
                                .cornerRadius(12)

                                Text(media.title ?? "No Title")
                                    .lineLimit(3)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 124)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                ViewStore(store.viewAction.stateless)
                                    .send(.didTapMedia(media))
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

                Text("Show All")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.gray)
                    .opacity(listing.items.isEmpty ? 0 : 1.0)
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
                            let media = listing.items[idx]
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(idx + 1)")
                                    .font(.title3.monospacedDigit().weight(.bold))

                                LazyImage(url: media.posterImage) { state in
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

                                Text(media.title ?? "Unknown")
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
                                    .send(.didTapMedia(media))
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
    func featuredListing(_ listing: DiscoverListing) -> some View {
        SnapScroll(items: listing.items) { media in
            LazyImage(url: media.posterImage) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Color.gray
                        .opacity(0.35)
                }
            }
        }
        .aspectRatio(5 / 7, contentMode: .fill)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
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
