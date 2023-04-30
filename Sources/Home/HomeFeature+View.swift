//
//  HomeFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import Architecture
import NukeUI
import SharedModels
import SwiftUI
import ViewComponents

extension HomeFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.listings) { viewStore in
            LoadableView(loadable: viewStore.state) { listings in
                if listings.isEmpty {
                    VStack(spacing: 12) {
                        topBarSpacer

                        Spacer()

                        Image(systemName: "questionmark.app.dashed")
                            .font(.largeTitle)

                        Text("No listings available for this module.")
                            .font(.subheadline.bold())
                        Spacer()

                        Spacer()
                            .frame(maxWidth: .infinity)
                            .frame(height: tabNavigationSize.height)
                    }
                } else {
                    buildListingsView(listings)
                }
            } failedView: { error in
                // TODO: Add error state depending on module or system fetching
                VStack(spacing: 12) {
                    topBarSpacer

                    Spacer()

                    Image(systemName: "exclamationmark.triangle.fill")

                    switch error {
                    case .module:
                        EmptyView()
                    case .system:
                        EmptyView()
                    }

                    Spacer()

                    Spacer()
                        .frame(maxWidth: .infinity)
                        .frame(height: tabNavigationSize.height)
                }
            } loadingView: {
                buildListingsView(
                    [
                        .init(
                            title: "placeholder",
                            type: .featured,
                            paging: .init(
                                items: [
                                    .init(id: "placeholder 1", meta: .video),
                                    .init(id: "placeholder 2", meta: .video),
                                    .init(id: "placeholder 3", meta: .video)
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
                                    .init(id: "placeholder 3", meta: .video)
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
                                    .init(id: "placeholder 3", meta: .video)
                                ],
                                currentPage: "demo-1"
                            )
                        )
                    ]
                )
                .redacted(reason: .placeholder)
                .disabled(true)
            }
            .animation(.easeInOut, value: viewStore.state.finished)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .edgesIgnoringSafeArea(.top)
        .overlay(topBar, alignment: .top)
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
    }
}

extension HomeFeature.View {
    @MainActor
    func buildListingsView(_ listings: [DiscoverListing]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            if !listings.contains(where: \.type == .featured) {
                topBarSpacer
            }

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

            Spacer()
                .frame(maxWidth: .infinity)
                .frame(height: tabNavigationSize.height)
        }
    }
}

extension HomeFeature.View {
    @MainActor
    var topBar: some View {
        HStack(spacing: 12) {
            Text("mochi")
                .font(.largeTitle.bold())
                .opacity(0.0)

            Spacer()

            Button {
                ViewStore(store.viewAction.stateless)
                    .send(.didTapOpenModules)
            } label: {
                HStack {
                    Text("Option 1")
                    Image(systemName: "chevron.up.chevron.down")
                }
                .font(.footnote.weight(.semibold))
                .padding(8)
                .padding(.horizontal, 4)
                .background(
                    BlurView()
                        .clipShape(Capsule())
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .readSize { size in
            optionSelectionSize = size
        }
    }

    @MainActor
    var topBarSpacer: some View {
        Spacer()
            .frame(maxWidth: .infinity)
            .frame(height: optionSelectionSize.vertical)
    }
}

extension HomeFeature.View {
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

                                Text(media.title ?? "Unknown")
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 132)
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
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeature.View(
            store: .init(
                initialState: .init(),
                reducer: EmptyReducer()
            )
        )
    }
}
