//
//  File.swift
//  
//
//  Created by ErrorErrorError on 11/23/23.
//  
//

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
        ZStack {
            GeometryReader { proxy in
                WithViewStore(store, observe: \.overlay == nil) { viewStore in
                    WithViewStore(store, observe: RateBufferingState.init) { rateBufferingState in
                        PlayerView(
                            player: player(),
                            gravity: gravity,
                            enablePIP: $enablePiP
                        )
                        // Reducer should not handle these properties, they should be binded to the view instead.
                        .pictureInPictureIsPossible { possible in
                            pipPossible = possible
                        }
                        .pictureInPictureIsSupported { supported in
                            pipSupported = supported
                        }
                        .pictureInPictureStatus { status in
                            pipStatus = status
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .ignoresSafeArea(.all, edges: .all)
                        .contentShape(Rectangle())
                        .gesture(
                            MagnificationGesture()
                                .onEnded { scale in
                                    if scale < 1 {
                                        gravity = .resizeAspect
                                    } else {
                                        gravity = .resizeAspectFill
                                    }
                                }
                        )
                        .gesture(SimultaneousGesture(TapGesture(count: 2), TapGesture(count: 1))
                            .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                           ).onEnded { value in
                            if (value.first?.first != nil) {
                                if proxy.size.width / 2 > (value.second?.location.x ?? .zero) {
                                    rateBufferingState.send(.view(.didSkipBackwards))
                                } else {
                                    rateBufferingState.send(.view(.didSkipForward))
                                }
                            } else {
                                store.send(.view(.didTapPlayer))
                            }
                        })
                        #if os(iOS)
                        .statusBarHidden(viewStore.state)
                        .animation(.easeInOut, value: viewStore.state)
                        #endif
                    }
                }
            }
        }
        .overlay {
            ZStack {
                contentStatusView
                toolsOverlay
                moreOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.black
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #if os(iOS)
        .blur(radius: pipStatus.isInPiP ? 30 : 0)
        .opacity(pipStatus.isInPiP ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.35), value: pipStatus.isInPiP)
        .prefersHomeIndicatorAutoHidden(pipStatus.isInPiP ? false : true)
        #endif
        .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
        .task { await store.send(.view(.didAppear)).finish() }
    }
}

extension VideoPlayerFeature.View {
    @MainActor
    var toolsOverlay: some View {
        WithViewStore(store, observe: \.overlay == .tools) { viewStore in
            VStack {
                if viewStore.state {
                    topBar
                }
                Spacer()
                skipButtons(viewStore.state)
                if viewStore.state {
                    bottomBar
                }
            }
            .overlay {
                if viewStore.state {
                    controlsBar
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if viewStore.state {
                    GeometryReader { proxy in
                        WithViewStore(store, observe: RateBufferingState.init) { rateBufferingState in
                            Color.black
                                .opacity(0.35)
                                .ignoresSafeArea()
                                .edgesIgnoringSafeArea(.all)
                                .gesture(
                                    MagnificationGesture()
                                        .onEnded { scale in
                                            if scale < 1 {
                                                gravity = .resizeAspect
                                            } else {
                                                gravity = .resizeAspectFill
                                            }
                                        }
                                )
                                .gesture(SimultaneousGesture(TapGesture(count: 2), TapGesture(count: 1))
                                    .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    ).onEnded { value in
                                        if (value.first?.first != nil) {
                                            if proxy.size.width / 2 > (value.second?.location.x ?? .zero) {
                                                rateBufferingState.send(.view(.didSkipBackwards))
                                            } else {
                                                rateBufferingState.send(.view(.didSkipForward))
                                            }
                                        } else {
                                            store.send(.view(.didTapPlayer))
                                        }
                                })
                        }
                    }
                }
            }
            .animation(.easeInOut, value: viewStore.state)
        }
    }

    @MainActor
    func skipButtons(_ showHidden: Bool) -> some View {
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
                            .swipeable(showHidden, .easeInOut(duration: 0.2))
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
        let groupId: Loadable<Playlist.Group>
        let episode: Loadable<Playlist.Item>

        init(_ state: VideoPlayerFeature.State) {
            self.playlist = state.playlist
            self.groupId = state.selectedGroup
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
                        switch viewStore.groupId {
                        case .pending, .loading:
                            EmptyView()
                        case let .loaded(groupId):
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
                                Text(groupId.altTitle ?? "S\(groupId.number.withoutTrailingZeroes)") +
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
                .onTapGesture {
                    store.send(.view(.didTapBackButton))
                }
            }

            Spacer()

            if pipSupported {
                Button {
                    enablePiP.toggle()
                } label: {
                    Image(systemName: "rectangle.inset.bottomright.filled")
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!pipPossible)
            }

            PlayerRoutePickerView()
                .scaleEffect(0.85)
                .frame(width: 28, height: 28)
                .fixedSize()

            Menu {
                ForEach(State.Overlay.MoreTab.allCases, id: \.self) { tab in
                    if tab == .speed {
                        WithViewStore(store, observe: \.playerSettings.speed) { viewStore in
                            Menu {
                                Picker(
                                    tab.rawValue,
                                    selection: viewStore.binding(get: \.`self`, send: { .view(.didChangePlaybackRate($0)) })
                                ) {
                                    ForEach([0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0], id: \.self) { value in
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
            .buttonStyle(.plain)
        }
        .foregroundColor(.white)
        .font(.body.weight(.medium))
    }

    private struct RateBufferingState: Equatable, Sendable {
        let isPlaying: Bool
        let isBuffering: Bool

        init(_ state: VideoPlayerFeature.State) {
            self.isPlaying = state.player.is(\.playback) ? (state.player.playback?.state == .playing) : false
            self.isBuffering = state.player.is(\.playback) ? (state.player.playback?.state == .buffering) : false
        }
    }

    @MainActor
    var controlsBar: some View {
        WithViewStore(store, observe: \.videoPlayerStatus == nil) { canShowControls in
            if canShowControls.state {
                WithViewStore(store, observe: RateBufferingState.init) { rateBufferingState in
                    HStack(spacing: 10) {
                        Spacer()

                        Button {
                            rateBufferingState.send(.view(.didSkipBackwards))
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
                                    rateBufferingState.send(.view(.didTogglePlayback))
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
                            rateBufferingState.send(.view(.didSkipForward))
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
            store: store.scope(
                state: \.player.playback,
                action: \.self
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
                    .buttonStyle(.plain)
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
            case variant
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
        } else if let content = selectedVariant.videoContentState(for: .variant) {
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
        } else if player == .error {
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
    @MainActor
    var moreOverlay: some View {
        WithViewStore(store, observe: \.overlay?.more) { viewStore in
            ZStack {
                if let selected = viewStore.state {
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
                                Rectangle()
                                    .fill(.thinMaterial)
                                    .preferredColorScheme(.dark)
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
            }
            .animation(.easeInOut, value: viewStore.state != nil)
        }
    }

    private struct EpisodeViewState: Equatable {
        let groupId: Playlist.Group.ID
        let variantId: Playlist.Group.Variant.ID
        let pageId: PagingID
        let itemId: Playlist.Item.ID

        init(_ state: VideoPlayerFeature.State) {
            self.groupId = state.selected.groupId
            self.variantId = state.selected.variantId
            self.pageId = state.selected.pageId
            self.itemId = state.selected.itemId
        }
    }

    @MainActor
    var episodes: some View {
        WithViewStore(store, observe: EpisodeViewState.init) { viewStore in
            ContentCore.View(
                store: store.scope(
                    state: \.content,
                    action: Action.InternalAction.content
                ),
                contentType: .video,
                selectedGroupId: viewStore.groupId,
                selectedVariantId: viewStore.variantId,
                selectedPageId: viewStore.pageId,
                selectedItemId: viewStore.itemId
            )
        }
    }

    @MainActor
    var sourcesAndServers: some View {
        WithViewStore(store) { state in
            state.loadables[episodeId: state.selected.itemId]
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
        let groupId: AVMediaSelectionGroup?

        init() {
            self.selected = nil
            self.groupId = nil
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

                    WithViewStore(store, observe: \.player.playback?.selections) { viewStore in
                        ForEach(viewStore.state ?? [], id: \.`self`) { group in
                            MoreListingRow(
                                title: group.displayName,
                                selected: { $0 == group.selected || $0 == group.defaultOption },
                                items: group.options,
                                itemTitle: \.displayName,
                                noneCallback: !group.allowsEmptySelection ? nil : {
                                    viewStore.send(.view(.didTapGroupOption(nil, for: group)))
                                },
                                selectedCallback: { option in
                                    viewStore.send(.view(.didTapGroupOption(option, for: group)))
                                }
                            )
                        }
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
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VideoPlayerFeature.View(
        store: .init(
            initialState: .init(
                repoModuleId: Repo().id(.init("")),
                playlist: .empty,
                loadables: .init(),
                group: .init(""),
                variant: .init(""),
                page: .init(""),
                episodeId: .init(""),
                overlay: .tools
            ),
            reducer: { EmptyReducer() }
        )
    )
    .previewInterfaceOrientation(.landscapeRight)
}
