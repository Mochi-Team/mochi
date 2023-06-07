//
//  PlaylistDetailsFeature+View.swift
//  
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleClient
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension PlaylistDetailsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.playlistInfo) { viewStore in
            ZStack {
                if viewStore.error != nil {
                    // TODO: Add error
                    VStack(spacing: 14) {
                        Text("Failed to retrieve contents.")
                            .font(.body.bold())
                            .contrast(0.75)

                        Button {
                            // TODO: Handle retry button tapped
                        } label: {
                            Text("Retry")
                                .font(.body.weight(.bold))
                                .padding(12)
                                .padding(.horizontal, 4)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            topView(viewStore.value ?? .init())
                            contentView(viewStore.value ?? .init())
                        }
                    }
                    .shimmering(active: !viewStore.didFinish)
                    .disabled(!viewStore.didFinish)
                }
            }
            .animation(.easeInOut, value: viewStore.didFinish)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            LinearGradient(
                stops: [
                    .init(
                        color: imageDominatColor ?? .init(uiColor: .systemBackground),
                        location: 0
                    ),
                    .init(
                        color: .init(uiColor: .systemBackground),
                        location: 1.0
                    )
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(.ultraThinMaterial, in: Rectangle())
            .edgesIgnoringSafeArea(.all)
            .ignoresSafeArea()
        )
        .edgesIgnoringSafeArea(.top)
        .ignoresSafeArea(.container, edges: .top)
        .topBar(backgroundStyle: .clear) {
            ViewStore(store.stateless.viewAction).send(.didTappedBackButton)
        } trailingAccessory: {
            // TODO: Make this change depending if it's in library already or not
            Button {
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.materialToolbarImage)

            Menu {
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.materialToolbarImage)
        }
        .onAppear {
            ViewStore(store.viewAction.stateless)
                .send(.didAppear)
        }
    }
}

extension PlaylistDetailsFeature.View {
    @MainActor
    func topView(_ playlistInfo: Self.State.PlaylistInfo) -> some View {
        ZStack(alignment: .bottom) {
            FillAspectImage(url: playlistInfo.posterImage) { color in
                withAnimation(.easeIn(duration: 0.25)) {
                    imageDominatColor = color
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .overlay {
                LinearGradient(
                    gradient: .easingLinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: imageDominatColor ?? .black, location: 1.0)
                        ],
                        easing: .init(curve: .exponential, function: .easeIn)
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(spacing: 0) {
                Text(playlistInfo.title ?? "Unknown Title")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if !playlistInfo.genres.isEmpty || playlistInfo.yearReleased != nil {
                    Spacer()
                        .frame(height: 8)

                    HStack(spacing: 4) {
                        let genres = playlistInfo.genres.prefix(3)
                        ForEach(genres, id: \.self) { genre in
                            Text(genre)
                            if genres.last != genre {
                                dotSpaced
                            }
                        }

                        if let released = playlistInfo.yearReleased {
                            if !genres.isEmpty {
                                dotSpaced
                            }
                            Text(released.description)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .contrast(0.9)
                }

                Spacer()
                    .frame(height: 12)

                Button {
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .foregroundColor(.label)
                    .font(.callout.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        (imageDominatColor ?? .init(white: 0.5))
                            .overlay(.regularMaterial)
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(readableColor)
            .frame(maxWidth: .infinity)
            .padding()

            // TODO: Add progress
        }
        .elasticParallax()
        .aspectRatio(5 / 7, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    func contentView(_ playlistInfo: Self.State.PlaylistInfo) -> some View {
        LazyVStack(spacing: 24) {

            // Description

            HeaderWithContent(title: "Description") {
                ExpandableText(playlistInfo.contentDescription ?? "Description is not available for this content.") {
                    // TODO: Show modal on read more
                }
                .lineLimit(3)
                .font(.callout)
                .padding(.horizontal)
            }

            // Previews

            if !playlistInfo.previews.isEmpty {
                HeaderWithContent(title: "Previews") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(playlistInfo.previews, id: \.link) { preview in
                                FillAspectImage(url: preview.thumbnail)
                                    .aspectRatio(preview.type == .image ? 2 / 3 : 16 / 9, contentMode: .fit)
                                    .overlay {
                                        if preview.type == .video {
                                            ZStack {
                                                Color.black.opacity(0.25)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                Image(systemName: "play.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.white)
                                                    .opacity(0.9)
                                                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 0)
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        // TODO: Handle tap gesture for video/image preview
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 128)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Contents
            // TODO: Figure out whether or not it should show contents
            WithViewStore(store.viewAction, observe: \.contents) { viewStore in
                HeaderWithContent {
                    if let value = viewStore.state.value, value.allGroups.count > 1 {
                        Menu {
                            ForEach(value.allGroups, id: \.id) { group in
                                Button {
                                } label: {
                                    Text(
                                        group.displayTitle ?? (
                                            playlistInfo.playlist.type == .video ?
                                                "Season \(group.id.withoutTrailingZeroes)" :
                                                "Volume \(group.id.withoutTrailingZeroes)"
                                        )
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                if let group = value.selectedGroup {
                                    Text(
                                        group.displayTitle ?? (
                                            playlistInfo.playlist.type == .video ?
                                                "Season \(group.id.withoutTrailingZeroes)" :
                                                "Volume \(group.id.withoutTrailingZeroes)"
                                        )
                                    )
                                } else {
                                    Text("Unknown")
                                }

                                Image(systemName: "chevron.down")
                                    .font(.footnote.weight(.bold))
                            }
                            .foregroundColor(.label)
                        }
                    } else {
                        Text(playlistInfo.playlist.type == .video ? "Episodes" : "Chapters")
                    }
                } content: {
                    ZStack {
                        if viewStore.error != nil {
                        } else {
                            if playlistInfo.playlist.type == .video {
                                buildVideoContents(playlistInfo, viewStore.state.value?.selectedContent ?? .pending)
                            } else {
                                buildImageTextContents(playlistInfo, viewStore.state.value?.selectedContent ?? .pending)
                            }
                        }
                    }
                    .animation(.easeInOut, value: viewStore.state.didFinish)
                }
                .shimmering(active: !viewStore.didFinish)
                .disabled(!viewStore.didFinish)
            }
        }
    }
}

extension PlaylistDetailsFeature.View {
    private static let placeholderItems = [
        Playlist.Item(
            id: "/1",
            title: "Placeholder",
            description: "Placeholder",
            number: 1,
            timestamp: "May 12, 2023",
            tags: []
        ),
        Playlist.Item(
            id: "/2",
            title: "Placeholder",
            description: "Placeholder",
            number: 2,
            timestamp: "May 12, 2023",
            tags: []
        ),
        Playlist.Item(
            id: "/3",
            title: "Placeholder",
            description: "Placeholder",
            number: 3,
            timestamp: "May 12, 2023",
            tags: []
        )
    ]

    @MainActor
    @ViewBuilder
    func buildVideoContents(
        _ playlistDetails: Self.State.PlaylistInfo,
        _ content: Loadable<Playlist.Group.Content, ModuleClient.Error>
    ) -> some View {
        ZStack {
            if content.error != nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.16))
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    // FIXME: Improve view height based on title
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(content.value?.items ?? Self.placeholderItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 0) {
                                FillAspectImage(url: item.thumbnail ?? playlistDetails.posterImage)
                                    .aspectRatio(16 / 9, contentMode: .fit)
                                    .cornerRadius(12)

                                Spacer()
                                    .frame(height: 8)

                                Text("Episode \(item.number.withoutTrailingZeroes)")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.init(white: 0.4))

                                Spacer()
                                    .frame(height: 4)

                                Text(item.title ?? "Episode \(item.number.withoutTrailingZeroes)")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(width: 228)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let content = content.value {
                                    ViewStore(store.viewAction.stateless).send(
                                        .didTapVideoItem(content.groupId, item.id)
                                    )
                                }
                                // TODO: Handle tap gesture for playlist video item
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .shimmering(active: !content.didFinish)
                .disabled(!content.didFinish)
            }
        }
        .animation(.easeIn, value: content)
    }

    @MainActor
    @ViewBuilder
    func buildImageTextContents(
        _ playlistDetails: Self.State.PlaylistInfo,
        _ content: Loadable<Playlist.Group.Content, ModuleClient.Error>
    ) -> some View {
        if content.error != nil {
        } else {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(content.value?.items ?? Self.placeholderItems, id: \.id) { item in
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title ?? "Chapter \(item.number.withoutTrailingZeroes)")
                            .foregroundColor(.label)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 4) {
                            Text("Chapter \(item.number.withoutTrailingZeroes)")
                            if let timestamp = item.timestamp {
                                dotSpaced
                                Text(timestamp)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.footnote.bold())
                .foregroundColor(.init(white: 0.4))
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
            .shimmering(active: !content.didFinish)
            .disabled(!content.didFinish)
        }
    }
}

extension PlaylistDetailsFeature.View {
    @MainActor
    struct HeaderWithContent<Label: View, Content: View>: View {
        let label: () -> Label
        let content: () -> Content

        @MainActor
        var body: some View {
            LazyVStack(alignment: .leading, spacing: 12) {
                label()
                    .font(.title3.bold())
                    .padding(.horizontal)
                content()
            }
            .frame(maxWidth: .infinity)
        }

        @MainActor
        init(
            @ViewBuilder label: @escaping () -> Label,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.label = label
            self.content = content
        }

        @MainActor
        init(
            title: String = "",
            @ViewBuilder content: @escaping () -> Content
        ) where Label == Text {
            self.init {
                Text(title)
            } content: {
                content()
            }
        }
    }
}

extension PlaylistDetailsFeature.View {
    @MainActor
    var dotSpaced: some View {
        Text("\u{2022}")
    }

    @MainActor
    var readableColor: Color {
        imageDominatColor?.isDark ?? true ? .white : .black
    }
}

struct PlaylistDetailsFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: ""
                    ),
                    playlist: .init(
                        id: "playlist-1",
                        title: "Playlist Demo",
                        type: .video
                    ),
                    details: .pending
                ),
                reducer: EmptyReducer()
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: ""
                    ),
                    playlist: .init(
                        id: "playlist-1",
                        title: "Playlist Demo",
                        type: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: []
                        )
                    )
                    ,
                    contents: .pending
                ),
                reducer: EmptyReducer()
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: ""
                    ),
                    playlist: .init(
                        id: "playlist-1",
                        title: "Playlist Demo",
                        type: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: []
                        )
                    ),
                    contents: .loaded(
                        .init(
                            .init(
                                content: .init(groupId: 0),
                                allGroups: [.init(id: 0)]
                            )
                        )
                    )
                ),
                reducer: EmptyReducer()
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: ""
                    ),
                    playlist: .init(
                        id: "playlist-1",
                        title: "Playlist Demo",
                        type: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: []
                        )
                    ),
                    contents: .loaded(
                        .init(
                            .init(
                                content: .init(
                                    groupId: 0,
                                    items: [.init(id: "", number: 0)]
                                ),
                                allGroups: [.init(id: 0)]
                            )
                        )
                    )
                ),
                reducer: EmptyReducer()
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: ""
                    ),
                    playlist: .init(
                        id: "playlist-1",
                        title: "Playlist Demo",
                        type: .video
                    ),
                    details: .failed(.unknown())
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
