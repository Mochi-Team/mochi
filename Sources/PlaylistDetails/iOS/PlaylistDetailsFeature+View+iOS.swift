//
//  PlaylistDetailsFeature+View+iOS.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

#if os(iOS)
import Architecture
import ComposableArchitecture
import ContentFetchingLogic
import ModuleClient
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - PlaylistDetailsFeature.View + View

extension PlaylistDetailsFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.playlistInfo) { viewStore in
            ZStack {
                if viewStore.error != nil {
                    VStack(spacing: 14) {
                        Text("Failed to retrieve contents.")
                            .font(.callout.bold())
                            .contrast(0.75)

                        Button {
                            // TODO: Handle retry button tapped
                        } label: {
                            Text("Retry")
                                .font(.callout.weight(.bold))
                                .padding(12)
                                .padding(.horizontal, 4)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            topView(viewStore.value ?? .init(playlist: .placeholder(0)))
                            contentView(viewStore.value ?? .init(playlist: .placeholder(0)))
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
            store.viewAction.send(.didTappedBackButton)
        } trailingAccessory: {
            // TODO: Make this change depending if it's in library already or not
            Button {
                
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.materialToolbarImage)

            Menu {
                WithViewStore(store, observe: \.playlist.url) { viewStore in
                    Button {
                        openURL(viewStore.state)
                    } label: {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Open Playlist URL")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.materialToolbarImage)
        }
        .onAppear {
            store.viewAction.send(.didAppear)
        }
    }
}

extension PlaylistDetailsFeature.View {
    @MainActor
    func topView(_ playlistInfo: PlaylistInfo) -> some View {
        GeometryReader { reader in
            FillAspectImage(url: playlistInfo.posterImage) { color in
                withAnimation(.easeIn(duration: 0.25)) {
                    imageDominatColor = color
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .overlay {
                LinearGradient(
                    gradient: .init(
                        colors: [.clear, readableColor.isDark ? .white : .black],
                        easing: .easeIn
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottom) {
                let color = imageDominatColor ?? .init(white: 0.5)
                VStack(spacing: 0) {
                    Text(playlistInfo.title ?? "No Title")
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    if !playlistInfo.genres.isEmpty || playlistInfo.yearReleased != nil {
                        Spacer()
                            .frame(height: 6)

                        HStack(spacing: 4) {
                            let genres = playlistInfo.genres.prefix(3)

                            if let released = playlistInfo.yearReleased {
                                Text(released.description)
                                if !genres.isEmpty {
                                    dotSpaced
                                }
                            }

                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                if genres.last != genre {
                                    dotSpaced
                                }
                            }
                        }
                        .font(.caption.weight(.medium))
                    }

                    Spacer()
                        .frame(height: 16)

                    WithViewStore(store, observe: \.resumableState) { viewStore in
                        if case let .`continue`(title, progress) = viewStore.state {
                            VStack(spacing: 4) {
                                HStack {
                                    Text(title)
                                    Spacer()
                                }

                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        readableColor
                                            .frame(maxWidth: proxy.size.width * progress)

                                        readableColor.opacity(0.5)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .clipShape(Capsule(style: .continuous))
                                .frame(maxWidth: .infinity)
                                .frame(height: 6)
                            }
                            .font(.footnote)
                            .foregroundColor(readableColor)

                            Spacer()
                                .frame(height: 12)
                        }

                        Button {
                            // TODO: Handle resume play
                        } label: {
                            HStack {
                                if let image = viewStore.state.image {
                                    image
                                }
                                Text(viewStore.state.description)
                            }
                            .foregroundColor(color.isDark ? .white : .black)
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(color)
                                    .brightness(0.1)
                                    .overlay(
                                        LinearGradient(
                                            gradient: .init(
                                                colors: [
                                                    .init(white: 1.0),
                                                    .init(white: 0.75)
                                                ],
                                                easing: .easeIn
                                            ),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .blendMode(.multiply),
                                        in: RoundedRectangle(
                                            cornerRadius: 8,
                                            style: .continuous
                                        )
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .animation(.easeIn(duration: 0.12), value: viewStore.state)
                        .animation(.easeIn(duration: 0.12), value: imageDominatColor)
                        .disabled(viewStore.state == .unavailable)
                        .shimmering(active: viewStore.state == .loading)
                    }
                }
                .foregroundColor(readableColor)
                .padding()
            }
            .frame(width: reader.size.width, height: reader.size.height)
        }
        .elasticParallax()
        .aspectRatio(5 / 7, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    func contentView(_ playlistInfo: PlaylistInfo) -> some View {
        LazyVStack(spacing: 24) {
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

            switch playlistInfo.type {
            case .video:
                PlaylistVideoContentView(
                    store: store.scope(
                        state: \.content,
                        action: { $0 }
                    ),
                    playlistInfo: playlistInfo
                )
            case .image:
                EmptyView()
            case .text:
                EmptyView()
            }
        }
    }
}

@MainActor
private struct PlaylistVideoContentView: View {
    let store: Store<ContentFetchingLogic.State, PlaylistDetailsFeature.Action>
    let playlistInfo: PlaylistInfo

    @State
    private var selectedGroup: Playlist.Group?

    @State
    private var selectedPage: Playlist.Group.Content.Page?

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
    var body: some View {
        WithViewStore(store.viewAction, observe: \.`self`) { viewStore in
            let defaultSelectedGroup = selectedGroup ?? viewStore.state.value.flatMap { $0.keys.first }

            let group = viewStore.state.flatMap { groups in
                defaultSelectedGroup.flatMap { groups[$0] } ?? groups.values.first ?? .loaded([:])
            }

            let defaultSelectedPage = selectedPage ?? group.value.flatMap { $0.keys.first }

            let page = group.flatMap { pages in
                defaultSelectedPage.flatMap { pages[$0] } ?? pages.values.first ?? .loaded(.init(id: ""))
            }

            HeaderWithContent {
                HStack {
                    if let value = viewStore.state.value, value.keys.count > 1 {
                        Menu {
                            ForEach(value.keys, id: \.self) { group in
                                Button {
                                    selectedGroup = group
                                    viewStore.send(.didTapContentGroup(group))
                                } label: {
                                    Text(group.displayTitle ?? "Group \(group.id.withoutTrailingZeroes)")
                                }
                            }
                        } label: {
                            HStack {
                                if let group = defaultSelectedGroup {
                                    Text(group.displayTitle ?? "Group \(group.id.withoutTrailingZeroes)")
                                } else {
                                    Text("Episodes")
                                }

                                if (viewStore.value?.count ?? 0) > 1 {
                                    Image(systemName: "chevron.down")
                                        .font(.footnote.weight(.bold))
                                }
                            }
                            .foregroundColor(.label)
                        }
                    } else {
                        if let group = defaultSelectedGroup {
                            Text(group.displayTitle ?? "Episodes")
                        }
                    }

                    Spacer()

                    if let pages = group.value, pages.keys.count > 1 {
                        Menu {
                            ForEach(pages.keys, id: \.id) { page in
                                Button {
                                    selectedPage = page
                                    if let defaultSelectedGroup {
                                        viewStore.send(.didTapContentGroupPage(defaultSelectedGroup, page))
                                    }
                                } label: {
                                    Text(page.displayName)
                                }
                            }
                        } label: {
                            HStack {
                                Text(defaultSelectedPage?.displayName ?? "Unknown")
                                    .font(.system(size: 14))
                                Image(systemName: "chevron.down")
                                    .font(.footnote.weight(.semibold))
                            }
                            .foregroundColor(.label)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(Color.gray.opacity(0.24))
                            }
                        }
                    }
                }
            } content: {
                ZStack {
                    if page.error != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.16))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 125)
                            .overlay {
                                Text("There was an error loading content.")
                                    .font(.callout.weight(.semibold))
                            }
                    } else if page.didFinish, (page.value?.items.count ?? 0) == 0 {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.12))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 125)
                            .overlay {
                                Text("There is no content available.")
                                    .font(.callout.weight(.medium))
                            }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            // FIXME: Improve view height based on title
                            LazyHStack(alignment: .top, spacing: 12) {
                                ForEach(page.value?.items ?? Self.placeholderItems, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: 0) {
                                        FillAspectImage(url: item.thumbnail ?? playlistInfo.posterImage)
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
                                        if let group = defaultSelectedGroup, let page = defaultSelectedPage {
                                            viewStore.send(.didTapVideoItem(group, page, item.id))
                                        }
                                    }
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .shimmering(active: !page.didFinish)
                        .disabled(!page.didFinish)
                    }
                }
                .animation(.easeInOut, value: viewStore.state)
                .animation(.easeInOut, value: selectedGroup)
                .animation(.easeInOut, value: selectedPage)
            }
            .shimmering(active: !viewStore.didFinish)
            .disabled(!viewStore.didFinish)
            .onChange(of: selectedGroup) { _ in
                selectedPage = nil
            }
        }
    }
}

// MARK: - HeaderWithContent

@MainActor
private struct HeaderWithContent<Label: View, Content: View>: View {
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

// MARK: - PlaylistDetailsFeatureView_Previews

struct PlaylistDetailsFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: .init("")
                    ),
                    playlist: .placeholder(0),
                    details: .pending,
                    content: .pending
                ),
                reducer: { EmptyReducer() }
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: .init("")
                    ),
                    playlist: .placeholder(0),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: .init()
                        )
                    ),
                    content: .pending
                ),
                reducer: { EmptyReducer() }
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: .init("")
                    ),
                    playlist: .placeholder(0),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: .init()
                        )
                    ),
                    content: .loading
                ),
                reducer: { EmptyReducer() }
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: .init("")
                    ),
                    playlist: .placeholder(0),
                    details: .loaded(
                        .init(
                            genres: ["Action", "Thriller"],
                            yearReleased: 2_023,
                            previews: .init()
                        )
                    ),
                    content: .loaded(.init())
                ),
                reducer: { EmptyReducer() }
            )
        )

        PlaylistDetailsFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(rawValue: .init(string: "/").unsafelyUnwrapped),
                        moduleId: .init("")
                    ),
                    playlist: .placeholder(0),
                    details: .failed(ModuleClient.Error.unknown())
                ),
                reducer: { EmptyReducer() }
            )
        )
    }
}
#endif
