//
//  MediaDetailsFeature+View.swift
//  
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

extension MediaDetailsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.mediaInfo) { viewStore in
            if let _ = viewStore.error {
                // TODO: Add error
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        topView(viewStore.value ?? .init())
                        contentView(viewStore.value ?? .init())
                    }
                }
                .shimmering(active: !viewStore.finished)
                .disabled(!viewStore.finished)
            }
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
            Image(systemName: "plus")
                .foregroundColor(.label)
                .font(.footnote.bold())
                .frame(width: 28, height: 28)
                .background(
                    .ultraThinMaterial,
                    in: Circle()
                )
                .contentShape(Rectangle())

            Menu {
                // TODO: Show extra buttons here, like share
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.label)
                    .font(.callout.bold())
                    .frame(width: 28, height: 28)
                    .background(
                        .ultraThinMaterial,
                        in: Circle()
                    )
                    .contentShape(Rectangle())
            }
        }
        .onAppear {
            ViewStore(store.viewAction.stateless)
                .send(.didAppear)
        }
    }
}

extension MediaDetailsFeature.View {
    @MainActor
    func topView(_ mediaInfo: MediaDetailsFeature.State.MediaDetails) -> some View {
        ZStack(alignment: .bottom) {
            FillAspectImage(url: mediaInfo.posterImage) { color in
                imageDominatColor = color
            }
            .overlay {
                LinearGradient(
                    gradient: .easingLinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: imageDominatColor ?? .black, location: 1.0)
                        ],
                        easing: .init(curve: .cubic, function: .easeIn)
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(spacing: 12) {
                Text(mediaInfo.title ?? "Unknown Title")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if !mediaInfo.genres.isEmpty || mediaInfo.yearReleased != nil {
                    HStack(spacing: 4) {
                        let genres = mediaInfo.genres.prefix(3)
                        ForEach(genres, id: \.self) { genre in
                            Text(genre)
                            if genres.last != genre {
                                dotSpaced
                            }
                        }

                        if let released = mediaInfo.yearReleased {
                            if !genres.isEmpty {
                                dotSpaced
                            }
                            Text(released.description)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .contrast(0.5)
                }

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
            .frame(maxWidth: .infinity)
            .padding()

            // TODO: Add progress
        }
        .foregroundColor(readableColor)
        .elasticParallax()
        .aspectRatio(5 / 7, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    func contentView(_ mediaInfo: MediaDetailsFeature.State.MediaDetails) -> some View {
        LazyVStack(spacing: 24) {
            // Description
            HeaderWithContent(title: "Description") {
                Text(mediaInfo.contentDescription ?? "Description is unavailable for this content.")
                    .font(.callout)
                    .padding(.horizontal)
            }

            // Previews
            if !mediaInfo.previews.isEmpty {
                HeaderWithContent(title: "Previews") {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 8) {
                            ForEach(mediaInfo.previews, id: \.link) { preview in
                                LazyImage(url: preview.thumbnail) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Color.gray.opacity(0.2)
                                            .aspectRatio(preview.type == .image ? 2 / 3 : 16 / 9, contentMode: .fit)
                                    }
                                }
                                .overlay {
                                    if preview.type == .video {
                                        Image(systemName: "play.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .opacity(0.9)
                                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 0)
                                    }
                                }
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                }
            }

            // Contents

            WithViewStore(store, observe: \.contents) { viewStore in
                HeaderWithContent {
                    // TODO: Switch between section or group type
                    Text(mediaInfo.media.meta == .video ? "Episodes" : "Chapters")
                } content: {
                    if let _ = viewStore.error {
                        // TODO: Add error type
                    } else {
                        let placeholders = [
                            Media.Content(
                                title: "Placeholder",
                                description: "Placeholder",
                                number: 1,
                                timestamp: "May 12, 2023",
                                tags: [],
                                link: "/1"
                            ),
                            Media.Content(
                                title: "Placeholder",
                                description: "Placeholder",
                                number: 2,
                                timestamp: "May 12, 2023",
                                tags: [],
                                link: "/2"
                            ),
                            Media.Content(
                                title: "Placeholder",
                                description: "Placeholder",
                                number: 3,
                                timestamp: "May 12, 2023",
                                tags: [],
                                link: "/3"
                            )
                        ]
                        if mediaInfo.media.meta == .video {
                            buildVideoContents(mediaInfo, viewStore.value ?? placeholders)
                        } else {
                            buildImageTextContents(mediaInfo, viewStore.value ?? placeholders)
                        }
                    }
                }
                .shimmering(active: !viewStore.finished)
                .disabled(!viewStore.finished)
            }
        }
    }
}

extension MediaDetailsFeature.View {
    @MainActor
    func buildVideoContents(
        _ mediaDetail: MediaDetailsFeature.State.MediaDetails,
        _ contents: [Media.Content] = []
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(contents, id: \.link) { content in
                    VStack(alignment: .leading, spacing: 0) {
                        FillAspectImage(url: content.thumbnail)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .cornerRadius(12)

                        Spacer()
                            .frame(height: 8)

                        Text("Episode \(content.number.withoutTrailingZeroes)")
                            .font(.callout)
                            .foregroundColor(.init(white: 0.4))

                        Spacer()
                            .frame(height: 4)

                        Text(content.title ?? "No Title")
                            .font(.body.weight(.semibold))
                    }
                    .frame(width: 228)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }

    @MainActor
    func buildImageTextContents(
        _ mediaDetail: MediaDetailsFeature.State.MediaDetails,
        _ contents: [Media.Content] = []
    ) -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(contents, id: \.link) { content in
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title ?? "Chapter \(content.number.withoutTrailingZeroes)")
                        .foregroundColor(.label)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let volume = content.group {
                        Text("Volume \(volume)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 4) {
                        Text("Chapter \(content.number.withoutTrailingZeroes)")
                        if let timestamp = content.timestamp {
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
    }
}

extension MediaDetailsFeature.View {
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

extension MediaDetailsFeature.View {
    @MainActor
    var dotSpaced: some View {
        Text("\u{2022}")
    }

    @MainActor
    var readableColor: Color {
        imageDominatColor?.isDark ?? true ? .white : .black
    }
}

struct MediaDetailsFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetailsFeature.View(
            store: .init(
                initialState: .init(
                    media: .init(
                        id: "media-1",
                        title: "Media Demo",
                        meta: .video
                    ),
                    details: .pending
                ),
                reducer: EmptyReducer()
            )
        )

        MediaDetailsFeature.View(
            store: .init(
                initialState: .init(
                    media: .init(
                        id: "media-1",
                        title: "Media Demo",
                        meta: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2023,
                            previews: []
                        )
                    ),
                    contents: .pending
                ),
                reducer: EmptyReducer()
            )
        )

        MediaDetailsFeature.View(
            store: .init(
                initialState: .init(
                    media: .init(
                        id: "media-1",
                        title: "Media Demo",
                        meta: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2023,
                            previews: []
                        )
                    ),
                    contents: .loaded([])
                ),
                reducer: EmptyReducer()
            )
        )

        MediaDetailsFeature.View(
            store: .init(
                initialState: .init(
                    media: .init(
                        id: "media-1",
                        title: "Media Demo",
                        meta: .video
                    ),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2023,
                            previews: []
                        )
                    ),
                    contents: .loaded([
                        .init(
                            title: "Some Title",
                            number: 1,
                            link: "/"
                        )
                    ])
                ),
                reducer: EmptyReducer()
            )
        )

        MediaDetailsFeature.View(
            store: .init(
                initialState: .init(
                    media: .init(
                        id: "media-1",
                        title: "Media Demo",
                        meta: .video
                    ),
                    details: .failed(.unknown())
                ),
                reducer: EmptyReducer()
            )
        )
    }
}
