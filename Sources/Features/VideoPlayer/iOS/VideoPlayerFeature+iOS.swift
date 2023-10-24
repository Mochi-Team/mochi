//
//  VideoPlayerFeature+iOS.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

#if os(iOS)
import Architecture
import AVFoundation
import AVKit
import ComposableArchitecture
import ContentCore
import PlayerClient
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

extension VideoPlayerFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.player.pipState.status.isInPiP) { viewStore in
            ZStack {
                PlayerFeature.View(
                    store: store.scope(
                        state: \.player,
                        action: Action.InternalAction.player
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewStore.send(.didTapPlayer)
                }
            }
            .overlay {
                WithViewStore(store, observe: \.overlay) { viewStore in
                    ZStack {
                        contentStatusView

                        switch viewStore.state {
                        case .none:
                            skipButtons
                                .padding()
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .bottomTrailing
                                )
                        case .tools:
                            toolsOverlay
                        case let .more(tab):
                            moreOverlay(tab)
                        }
                    }
                    .animation(.easeInOut, value: viewStore.state)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea(.all, edges: .all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .blur(radius: viewStore.state ? 30 : 0)
            .opacity(viewStore.state ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.35), value: viewStore.state)
            .prefersHomeIndicatorAutoHidden(viewStore.state ? false : true)
        }
        .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
        .onAppear {
            store.send(.view(.didAppear))
        }
    }
}

extension VideoPlayerFeature.View {
    @MainActor
    var toolsOverlay: some View {
        VStack {
            topBar
            Spacer()
            skipButtons
            bottomBar
        }
        .overlay { controlsBar }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.black
                .opacity(0.35)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    store.send(.view(.didTapPlayer))
                }
        }
    }

    @MainActor
    var skipButtons: some View {
        WithViewStore(
            store,
            observe: SkipActionViewState.init
        ) { viewState in
            ZStack {
                if viewState.visible {
                    HStack {
                        Spacer()
                        ForEach(viewState.actions, id: \.self) { action in
                            Button {
                                viewState.send(action.action)
                            } label: {
                                HStack {
                                    Image(systemName: action.image)
                                    Text(action.description)
                                }
                                .font(.system(size: 13).weight(.heavy))
                                .foregroundColor(action.textColor)
                                .padding(12)
                                .background(action.background.opacity(0.8))
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .shadow(color: Color.gray.opacity(0.25), radius: 6)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .swipeable(.easeInOut(duration: 0.2))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(
                .easeInOut(duration: 0.25),
                value: viewState.state
            )
        }
        .padding(.vertical, 4)
    }

    private struct PlaylistDisplayState: Equatable, Sendable {
        let playlist: Playlist
        let group: Loadable<Playlist.Group>
        let episode: Loadable<Playlist.Item>

        init(_ state: VideoPlayerFeature.State) {
            self.playlist = state.playlist
            self.group = state.selectedGroup.flatMap { _ in .loaded(state.selected.group) }
            self.episode = state.selectedItem
        }
    }

    @MainActor
    var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                store.send(.view(.didTapBackButton))
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            WithViewStore(store, observe: PlaylistDisplayState.init) { viewStore in
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        switch viewStore.group {
                        case .pending, .loading:
                            EmptyView()
                        case let .loaded(group):
                            Group {
                                switch viewStore.episode {
                                case .pending, .loading:
                                    Text("Loading...")
                                case let .loaded(item):
                                    Text(item.title ?? "Episode \(item.number.withoutTrailingZeroes)")
                                case .failed:
                                    EmptyView()
                                }
                            }

                            Group {
                                Text(group.displayTitle ?? "S\(group.id.withoutTrailingZeroes)") +
                                    Text("\u{2022}") +
                                    Text("E\(viewStore.episode.value?.number.withoutTrailingZeroes ?? "0")")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.init(white: 0.78))
                        case .failed:
                            EmptyView()
                        }
                    }
                    .font(.callout.weight(.semibold))

                    Spacer()
                        .frame(height: 2)

//                    Text(viewStore.playlist.title ?? "No title")
//                        .font(.footnote)
                }
            }

            Spacer()

            WithViewStore(
                store.scope(
                    state: \.player,
                    action: Action.InternalAction.player
                ),
                observe: \.pipState
            ) { viewStore in
                if viewStore.isSupported {
                    Button {
                        viewStore.send(.view(.didTogglePictureInPicture))
                    } label: {
                        Image(systemName: "rectangle.inset.bottomright.filled")
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewStore.isPossible)
                }
            }

            PlayerRoutePickerView()
                .scaleEffect(0.85)
                .frame(width: 28, height: 28)
                .fixedSize()

            Menu {
                ForEach(VideoPlayerFeature.State.Overlay.MoreTab.allCases, id: \.self) { tab in
                    if tab == .speed {
                        WithViewStore(
                            store.scope(
                                state: \.player,
                                action: Action.InternalAction.player
                            ),
                            observe: \.rate
                        ) { viewStore in
                            Menu {
                                Picker(
                                    tab.rawValue,
                                    selection: viewStore.binding(get: \.`self`, send: { .didSelectRate($0) })
                                ) {
                                    let values: [Float] = [0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0]
                                    ForEach(values, id: \.self) { value in
                                        Text(String(format: "%.2f", value) + "x")
                                            .tag(value)
                                    }
                                }
                            } label: {
                                tab.image
                                Text(tab.rawValue)
                            }
                        }
                    } else {
                        Button {
                            store.send(.view(.didSelectMoreTab(tab)))
                        } label: {
                            tab.image
                            Text(tab.rawValue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .rotationEffect(.degrees(90))
            }
        }
        .foregroundColor(.white)
        .font(.body.weight(.medium))
    }

    private struct RateBufferingState: Equatable, Sendable {
        let isPlaying: Bool
        let isBuffering: Bool

        init(_ state: PlayerFeature.State) {
            self.isPlaying = state.rate != 0
            self.isBuffering = state.isBuffering
        }
    }

    @MainActor
    var controlsBar: some View {
        WithViewStore(store, observe: \.videoPlayerStatus == nil) { canShowControls in
            if canShowControls.state {
                WithViewStore(
                    store.scope(
                        state: \.player,
                        action: Action.InternalAction.player
                    ),
                    observe: RateBufferingState.init
                ) { rateBufferingState in
                    HStack(spacing: 0) {
                        Spacer()

                        Button {
                            rateBufferingState.send(.view(.didTapGoBackwards))
                        } label: {
                            Image(systemName: "gobackward")
                                .font(.title2.weight(.bold))
                                .padding(12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Group {
                            if rateBufferingState.isBuffering {
                                ProgressView()
                                    .scaleEffect(1.25)
                            } else {
                                Button {
                                    rateBufferingState.send(.view(.didTogglePlayButton))
                                } label: {
                                    Image(systemName: rateBufferingState.isPlaying ? "pause.fill" : "play.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .font(.largeTitle)
                                        .padding(12)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: 54, height: 54)

                        Button {
                            rateBufferingState.send(.view(.didTapGoForwards))
                        } label: {
                            Image(systemName: "goforward")
                                .font(.title2.weight(.bold))
                                .padding(12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
            }
        }
        .foregroundColor(.white)
    }

    @MainActor
    var bottomBar: some View {
        ProgressBar(
            store.scope(
                state: \.player,
                action: Action.InternalAction.player
            )
        )
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
    }

    @MainActor
    var contentStatusView: some View {
        WithViewStore(store, observe: \.videoPlayerStatus) { viewStore in
            switch viewStore.state {
            case let .some(.loading(type)):
                ProgressView("Loading \(type.rawValue)...")

            case let .some(.needSelection(type)):
                VStack(alignment: .leading) {
                    Text("Content Error")
                        .font(.title2.bold())
                    Text("Please select a \(type.rawValue) to load.")
                }

            case let .some(.empty(type)):
                VStack(alignment: .leading) {
                    Text("Content Error")
                        .font(.title2.bold())
                    Text("There are no \(type.rawValue)s for this content.")
                }

            case let .some(.failed(type)):
                VStack(alignment: .leading) {
                    Text("Content Error")
                        .font(.title2.bold())
                    Text("There was an error loading \(type.rawValue). Please try again later.")
                        .font(.callout)

                    Button {} label: {
                        Text("Retry")
                            .padding(12)
                            .background(Color(white: 0.16))
                            .cornerRadius(6)
                    }
                }
            default:
                EmptyView()
            }
        }
        .foregroundColor(.white)
    }
}

extension VideoPlayerFeature.State {
    enum VideoPlayerState: Equatable {
        case pending(ContentType)
        case loading(ContentType)
        case empty(ContentType)
        case needSelection(ContentType)
        case failed(ContentType)

        enum ContentType: String, Equatable {
            case group
            case page
            case episode
            case source
            case server
            case link
            case playback
        }

        var action: VideoPlayerFeature.Action.ViewAction? { nil }
    }

    var videoPlayerStatus: VideoPlayerState? {
        if let content = selectedGroup.videoContentState(for: .group) {
            return content
        } else if let content = selectedPage.videoContentState(for: .page) {
            return content
        } else if let content = selectedItem.videoContentState(for: .episode) {
            return content
        } else if let content = selectedSource.videoContentState(for: .source) {
            return content
        } else if let content = selectedServer.videoContentState(for: .server) {
            return content
        } else if let content = selectedServerResponse.videoContentState(for: .server) {
            return content
        } else if let content = selectedLink.videoContentState(for: .link) {
            return content
        } else if player.status == .failed {
            return .failed(.playback)
        }

        return nil
    }
}

private extension Loadable {
    func videoContentState(for content: VideoPlayerFeature.State.VideoPlayerState.ContentType) -> VideoPlayerFeature.State.VideoPlayerState? {
        switch self {
        case .pending:
            return .pending(content)
        case .loading:
            return .loading(content)
        case let .loaded(t):
            if let t = t as? (any _OptionalProtocol) {
                if t.optional == nil {
                    return .needSelection(content)
                }
            }
            return nil
        case .failed:
            return .failed(content)
        }
    }
}

extension VideoPlayerFeature.View {
    struct ProgressBar: View {
        @ObservedObject
        var viewStore: ViewStore<PlayerFeature.State, PlayerFeature.Action.ViewAction>

        private var progress: Double {
            if canUseControls {
                min(1.0, max(0, viewStore.progress.seconds / viewStore.duration.seconds))
            } else {
                .zero
            }
        }

        @SwiftUI.State
        private var dragProgress: Double?

        private var isDragging: Bool {
            dragProgress != nil
        }

        private var canUseControls: Bool {
            viewStore.duration.isValid && !viewStore.duration.seconds.isNaN && viewStore.duration != .zero
        }

        init(_ store: StoreOf<PlayerFeature>) {
            self.viewStore = .init(store, observe: \.`self`)
        }

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            BlurView(.systemUltraThinMaterialLight)
                            Color.white
                                .frame(
                                    width: proxy.size.width * (isDragging ? dragProgress ?? progress : progress),
                                    height: proxy.size.height,
                                    alignment: .leading
                                )
                        }
                        .frame(
                            width: proxy.size.width,
                            height: isDragging ? 12 : 8
                        )
                        .clipShape(Capsule(style: .continuous))
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDragging {
                                    viewStore.send(.didStartedSeeking)
                                    dragProgress = progress
                                }

                                let locationX = value.location.x
                                let percentage = locationX / proxy.size.width

                                dragProgress = max(0, min(1.0, percentage))
                            }
                            .onEnded { _ in
                                if let dragProgress {
                                    viewStore.send(.didFinishedSeekingTo(dragProgress))
                                }
                                dragProgress = nil
                            }
                    )
                    .animation(.spring(response: 0.3), value: isDragging)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 24)

                Group {
                    if canUseControls {
                        Text(progressDisplayTime) +
                            Text(" / ") +
                            Text(viewStore.duration.displayTime ?? "--.--")
                    } else {
                        Text("--.-- / --.--")
                    }
                }
                .font(.caption.monospacedDigit())
            }
            .disabled(!canUseControls)
        }

        private var progressDisplayTime: String {
            if canUseControls {
                if isDragging {
                    @Dependency(\.dateComponentsFormatter)
                    var formatter

                    formatter.unitsStyle = .positional
                    formatter.zeroFormattingBehavior = .pad

                    let time = (dragProgress ?? .zero) * viewStore.duration.seconds

                    if time < 60 * 60 {
                        formatter.allowedUnits = [.minute, .second]
                    } else {
                        formatter.allowedUnits = [.hour, .minute, .second]
                    }

                    return formatter.string(from: time) ?? "00:00"
                } else {
                    return viewStore.progress.displayTime ?? "00:00"
                }
            } else {
                return "--:--"
            }
        }
    }
}

extension VideoPlayerFeature.View {
    @MainActor
    func moreOverlay(_ selected: VideoPlayerFeature.State.Overlay.MoreTab) -> some View {
        GeometryReader { proxy in
            DynamicStack(stackType: proxy.size.width < proxy.size.height ? .vstack() : .hstack()) {
                VStack(alignment: .trailing) {
                    Button {
                        store.send(.view(.didTapCloseMoreOverlay))
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .padding([.top, .trailing], 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)

                    Spacer()

                    Group {
                        switch selected {
                        case .episodes:
                            episodes
                        case .sourcesAndServers:
                            sourcesAndServers
                        case .speed:
                            EmptyView()
                        case .qualityAndSubtitles:
                            qualityAndSubtitles
                        case .settings:
                            settings
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Group {
                if selected == .episodes {
                    BlurView(.systemThinMaterialDark)
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                }
            }
            .edgesIgnoringSafeArea(.all)
            .ignoresSafeArea(.all, edges: .all)
        }
        .foregroundColor(.white)
    }

    @MainActor
    private struct PlaylistVideoContentView: View {
        let store: Store<ContentCore.State, VideoPlayerFeature.Action>
        let playlist: Playlist

        let selectedItem: Playlist.Item.ID?

        @SwiftUI.State
        var selectedGroup: Playlist.Group?

        @SwiftUI.State
        var selectedPage: Playlist.Group.Content.Page?

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
            WithViewStore(store, observe: \.`self`) { viewStore in
                let defaultSelectedGroup = selectedGroup ?? viewStore.state.value.flatMap(\.keys.first)

                let group = viewStore.state.flatMap { groups in
                    defaultSelectedGroup.flatMap { groups[$0] } ?? groups.values.first ?? .loaded([:])
                }

                let defaultSelectedPage = selectedPage ?? group.value.flatMap(\.keys.first)

                let page = group.flatMap { pages in
                    defaultSelectedPage.flatMap { pages[$0] } ?? pages.values.first ?? .loaded(.init(id: ""))
                }

                VStack(spacing: 8) {
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
                            ScrollViewReader { scrollReader in
                                ScrollView(.vertical, showsIndicators: false) {
                                    Spacer()
                                        .frame(height: 24)

                                    LazyVGrid(columns: [.init(), .init(), .init()]) {
                                        ForEach(page.value?.items ?? Self.placeholderItems, id: \.id) { item in
                                            VStack(alignment: .leading, spacing: 0) {
                                                FillAspectImage(url: item.thumbnail ?? playlist.posterImage)
                                                    .aspectRatio(16 / 9, contentMode: .fit)
                                                    .cornerRadius(12)

                                                Spacer()
                                                    .frame(height: 8)

                                                Text("Episode \(item.number.withoutTrailingZeroes)")
                                                    .font(.footnote.weight(.semibold))
                                                    .foregroundColor(.init(white: 0.72))

                                                Spacer()
                                                    .frame(height: 4)

                                                Text(item.title ?? "Episode \(item.number.withoutTrailingZeroes)")
                                                    .font(.callout.weight(.semibold))
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                if item.id == selectedItem {
                                                    Text("Playing")
                                                        .font(.footnote.weight(.bold))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Capsule(style: .continuous).fill(Color.white))
                                                        .padding(8)
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                if let group = defaultSelectedGroup, let page = defaultSelectedPage {
                                                    viewStore.send(.didTapPlayEpisode(group, page, item.id))
                                                }
                                            }
                                        }
                                    }
                                    .onAppear {
                                        scrollReader.scrollTo(selectedItem)
                                    }
                                }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
        }
    }

    struct EpisodesViewState: Equatable, Sendable {
        let playlist: Playlist
        let group: Playlist.Group?
        let page: Playlist.Group.Content.Page?
        let itemId: Playlist.Item.ID?

        init(_ state: VideoPlayerFeature.State) {
            self.playlist = state.playlist
            self.group = state.selected.group
            self.page = state.selected.page
            self.itemId = state.selected.episodeId
        }
    }

    @MainActor
    var episodes: some View {
        WithViewStore(store, observe: EpisodesViewState.init) { viewStore in
            PlaylistVideoContentView(
                store: store.scope(
                    state: \.loadables.contents,
                    action: { $0 }
                ),
                playlist: viewStore.playlist,
                selectedItem: viewStore.itemId,
                selectedGroup: viewStore.group,
                selectedPage: viewStore.page
            )
        }
    }

    @MainActor
    var sourcesAndServers: some View {
        WithViewStore(store) { state in
            state.loadables[episodeId: state.selected.episodeId]
        } content: { loadableSourcesStore in
            LoadableView(loadable: loadableSourcesStore.state) { playlistItemSourcesLoadables in
                VStack(alignment: .leading, spacing: 8) {
                    WithViewStore(store, observe: \.selected.sourceId) { selected in
                        MoreListingRow(
                            title: "Sources",
                            selected: selected.state,
                            items: playlistItemSourcesLoadables,
                            itemTitle: \.displayName,
                            selectedCallback: { id in
                                selected.send(.didTapSource(id))
                            }
                        )
                    }

                    Spacer()
                        .frame(height: 2)

                    WithViewStore(store, observe: \.selected.sourceId) { selectedSourceIdState in
                        WithViewStore(store, observe: \.selected.serverId) { selectedServerIdState in
                            MoreListingRow(
                                title: "Servers",
                                selected: selectedServerIdState.state,
                                items: selectedSourceIdState.state.flatMap { playlistItemSourcesLoadables[id: $0] }?.servers ?? [],
                                itemTitle: \.displayName,
                                selectedCallback: { id in
                                    selectedServerIdState.send(.didTapServer(id))
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            } failedView: { _ in
                Text("Failed to load sources.")
            } waitingView: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct SelectedSubtitle: Equatable {
        let selected: AVMediaSelectionOption?
        let group: AVMediaSelectionGroup?

        init(_ state: PlayerFeature.State) {
            self.selected = state.selectedSubtitle
            self.group = state.subtitles
        }
    }

    @MainActor
    var qualityAndSubtitles: some View {
        WithViewStore(store, observe: \.selectedServerResponse) { loadableServerResponseState in
            LoadableView(loadable: loadableServerResponseState.state) { response in
                VStack(alignment: .leading, spacing: 8) {
                    WithViewStore(store, observe: \.selected.linkId) { selectedState in
                        MoreListingRow(
                            title: "Quality",
                            selected: selectedState.state,
                            items: response.links,
                            itemTitle: \.quality.description,
                            selectedCallback: { id in
                                selectedState.send(.didTapLink(id))
                            }
                        )
                    }

                    Spacer()
                        .frame(height: 2)

                    WithViewStore(
                        store.scope(
                            state: \.player,
                            action: Action.InternalAction.player
                        ),
                        observe: SelectedSubtitle.init
                    ) { viewStore in
                        MoreListingRow(
                            title: "Subtitles",
                            selected: { $0 == viewStore.selected },
                            items: viewStore.group?.options ?? [],
                            itemTitle: \.displayName,
                            noneCallback: viewStore.group.flatMap { group in
                                group.allowsEmptySelection ? { viewStore.send(.didTapSubtitle(for: group, nil)) } : nil
                            },
                            selectedCallback: { option in
                                if let group = viewStore.group {
                                    viewStore.send(.didTapSubtitle(for: group, option))
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            } failedView: { _ in
                Text("Failed to load server contents.")
            } waitingView: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    var settings: some View {
        EmptyView()
    }

    @MainActor
    private struct MoreListingRow<T>: View {
        var title: String
        var items: [T]
        var selected: (T) -> Bool
        let itemTitle: (T) -> String
        var noneCallback: (() -> Void)?
        var selectedCallback: ((T) -> Void)?

        init(
            title: String,
            selected: @escaping (T) -> Bool,
            items: [T],
            itemTitle: @escaping (T) -> String,
            noneCallback: (() -> Void)? = nil,
            selectedCallback: ((T) -> Void)? = nil
        ) {
            self.title = title
            self.selected = selected
            self.items = items
            self.itemTitle = itemTitle
            self.noneCallback = noneCallback
            self.selectedCallback = selectedCallback
        }

        init(
            title: String,
            selected: T.ID? = nil,
            items: [T],
            itemTitle: KeyPath<T, String>,
            noneCallback: (() -> Void)? = nil,
            selectedCallback: ((T.ID) -> Void)? = nil
        ) where T: Identifiable {
            self.init(
                title: title,
                selected: { $0.id == selected },
                items: items,
                itemTitle: { $0[keyPath: itemTitle] },
                noneCallback: noneCallback,
                selectedCallback: selectedCallback.flatMap { callback in { callback($0.id) } }
            )
        }

        @MainActor
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if items.isEmpty || noneCallback != nil {
                            makeTextButton(
                                "None",
                                isSelected: items.isEmpty || !items.contains(where: selected)
                            ) {
                                noneCallback?()
                            }
                            .disabled(noneCallback == nil)
                        }

                        if let item = items.first(where: selected) {
                            makeTextButton(
                                itemTitle(item),
                                isSelected: true
                            ) {
                                selectedCallback?(item)
                            }
                        }

                        ForEach(Array(zip(items.indices, items)), id: \.0) { _, item in
                            if !selected(item) {
                                makeTextButton(
                                    itemTitle(item),
                                    isSelected: selected(item)
                                ) {
                                    withAnimation(.easeInOut) {
                                        selectedCallback?(item)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
        }

        @MainActor
        func makeTextButton(_ text: String, isSelected: Bool, callback: @escaping () -> Void) -> some View {
            Button {
                callback()
            } label: {
                Text(text)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(isSelected ? .black : .white)
                    .padding(12)
                    .background(Color(white: isSelected ? 1.0 : 0.24))
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
    }
}
#endif

#Preview {
    VideoPlayerFeature.View(
        store: .init(
            initialState: .init(
                repoModuleID: .init(
                    repoId: .init(
                        .init(string: "/").unsafelyUnwrapped
                    ),
                    moduleId: .init("")
                ),
                playlist: .empty,
                loadables: .init(),
                selected: .init(
                    group: .init(id: .init(0)),
                    page: .init(id: .init(""), displayName: ""),
                    episodeId: .init("")
                ),
                overlay: .tools
            ),
            reducer: { EmptyReducer() }
        )
    )
    .previewInterfaceOrientation(.landscapeRight)
}
