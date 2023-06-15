//
//  VideoPlayerFeature+iOS.swift
//
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

#if os(iOS)
import Architecture
import AVKit
import ComposableArchitecture
import PlayerClient
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// TODO: Hide home indicator
extension VideoPlayerFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store.viewAction, observe: \.player.pipState.status.isInPiP) { viewStore in
            ZStack {
                PlayerFeature.View(
                    store: store.internalAction.scope(
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
                WithViewStore(store.viewAction, observe: \.overlay) { viewStore in
                    ZStack {
                        switch viewStore.state {
                        case .none:
                            EmptyView()
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
            .preferredColorScheme(.dark)
            .blur(radius: viewStore.state ? 30 : 0)
            .opacity(viewStore.state ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.35), value: viewStore.state)
        }
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
    }
}

extension VideoPlayerFeature.View {
    @MainActor
    var toolsOverlay: some View {
        VStack {
            topBar
            Spacer()
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
                .allowsHitTesting(false)
        }
    }

    private struct PlaylistDisplayState: Equatable, Sendable {
        let playlist: Playlist
        let group: Loadable<Playlist.Group?>
        let episode: Loadable<Playlist.Item?>

        init(_ state: VideoPlayerFeature.State) {
            playlist = state.playlist
            group = state.contents.allGroups.map { $0[id: state.selected.groupId] }
            episode = state.contents.groups[state.selected.groupId]?.map { $0.items[id: state.selected.episodeId] } ?? .pending
        }
    }

    @MainActor
    var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                ViewStore(store.viewAction.stateless).send(.didTapBackButton)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            WithViewStore(store.viewAction, observe: PlaylistDisplayState.init) { viewStore in
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        switch viewStore.group {
                        case .pending, .loading:
                            EmptyView()
                        case let .loaded(group):
                            if let group {
                                Group {
                                    switch viewStore.episode {
                                    case .pending, .loading:
                                        Text("Loading...")
                                    case let .loaded(.some(item)):
                                        Text(item.title ?? "Episode \(item.number.withoutTrailingZeroes)")
                                    case .loaded(.none):
                                        Text("Unknown")
                                    case .failed:
                                        EmptyView()
                                    }
                                }
                                .foregroundColor(nil)

                                Group {
                                    Text("S\(group.id.withoutTrailingZeroes)") +
                                    Text("\u{2022}") +
                                    Text("E\(viewStore.episode.value??.number.withoutTrailingZeroes ?? "0")")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.init(white: 0.78))
                            } else {
                                Text("Unknown")
                            }
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
                store.internalAction.scope(
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

            Button {
            } label: {
                Image(systemName: "airplayvideo")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(
                    VideoPlayerFeature.State.Overlay.MoreTab.allCases,
                    id: \.self
                ) { tab in
                    Button {
                        ViewStore(store.viewAction.stateless)
                            .send(.didSelectMoreTab(tab))
                    } label: {
                        Text(tab.rawValue)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .rotationEffect(.degrees(90))
            }
        }
        .font(.body.weight(.medium))
    }

    @MainActor
    var controlsBar: some View {
        WithViewStore(
            store.internalAction.scope(
                state: \.player,
                action: Action.InternalAction.player
            ),
            observe: \.rate
        ) { isPlayingState in
            HStack(spacing: 0) {
                Spacer()

                Button {
                    isPlayingState.send(.view(.didTapGoBackwards))
                } label: {
                    Image(systemName: "gobackward")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    isPlayingState.send(.view(.didTogglePlayButton))
                } label: {
                    Image(systemName: isPlayingState.state > .zero ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    isPlayingState.send(.view(.didTapGoForwards))
                } label: {
                    Image(systemName: "goforward")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    @MainActor
    var bottomBar: some View {
        ProgressBar(
            store.internalAction.scope(
                state: \.player,
                action: Action.InternalAction.player
            )
        )
        .frame(maxWidth: .infinity)
    }
}

extension VideoPlayerFeature.View {
    struct ProgressBar: View {
        @ObservedObject
        var viewStore: ViewStore<PlayerFeature.State, PlayerFeature.Action.ViewAction>

        private var progress: Double {
            if canUseControls {
                return min(1.0, max(0, viewStore.progress.seconds / viewStore.duration.seconds))
            } else {
                return .zero
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

        init(_ store: StoreOf<PlayerFeature.Reducer>) {
            self.viewStore = .init(store.viewAction, observe: \.`self`)
        }

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Color.gray.opacity(0.35)
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
                        ViewStore(store.viewAction.stateless)
                            .send(.didTapCloseMoreOverlay)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .padding([.top, .trailing], 20)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer()

                    Group {
                        switch selected {
                        case .episodes:
                            episodes
                        case .sourcesAndServers:
                            sourcesAndServers
                        case .speed:
                            speed
                        case .qualityAndSubtitles:
                            qualityAndSubtitles
                        case .settings:
                            settings
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Group {
                if selected == .episodes {
                    Rectangle()
                        .fill(.thinMaterial)
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
    var episodes: some View {
        WithViewStore(store.viewAction, observe: \.contents.allGroups) { allGroupsStore in
            LoadableView(loadable: allGroupsStore.state) { allGroups in
                WithViewStore(
                    store,
                    observe: \.selected.groupId
                ) { selectedGroupStore in
                    VStack(spacing: 0) {
                        Menu {
                            ForEach(allGroups) { group in
                                Text(group.displayTitle ?? "Season \(group.id)")
                            }
                        } label: {
                            if allGroups.count == 1 {
                                Text("Episodes")
                            } else if let group = allGroups[id: selectedGroupStore.state] {
                                Text(group.displayTitle ?? "Season \(group.id)")
                            } else {
                                Text("Unknown Group")
                            }
                        }
                        .disabled(allGroups.count <= 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title2.weight(.semibold))

                        Spacer()
                            .frame(height: 12)

                        Divider()

                        WithViewStore(
                            store.viewAction,
                            observe: \.contents[groupId: selectedGroupStore.state]
                        ) { groupStore in
                            let playlist = ViewStore(store.actionless, observe: \.playlist).state
                            LoadableView(loadable: groupStore.state) { group in
                                ScrollView(.vertical, showsIndicators: false) {
                                    Spacer()
                                        .frame(height: 24)

                                    LazyVGrid(columns: [.init(), .init(), .init()]) {
                                        ForEach(group.items) { item in
                                            VStack(alignment: .leading, spacing: 0) {
                                                FillAspectImage(url: item.thumbnail ?? playlist.posterImage)
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
                                                    .font(.callout.weight(.semibold))
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                groupStore.send(.didTapPlayEpisode(group.groupId, item.id))
                                            }
                                        }
                                    }
                                }
                            } failedView: { _ in
                                Spacer()
                                Text("Retry")
                                Spacer()
                            } waitingView: {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                }
            } failedView: { _ in
                Text("Failed To Fetch Groups")
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    var sourcesAndServers: some View {
        WithViewStore(store.viewAction) { state in
            state.contents[episodeId: state.selected.episodeId]
        } content: { loadableSourcesStore in
            LoadableView(loadable: loadableSourcesStore.state) { sources in
                VStack(alignment: .leading, spacing: 8) {
                    WithViewStore(store.viewAction, observe: \.selected.sourceId) { selected in
                        MoreListingRow(
                            title: "Sources",
                            selected: selected.state,
                            items: sources,
                            itemTitle: \.displayName,
                            selectedCallback: { id in
                                selected.send(.didTapSource(id))
                            }
                        )
                    }

                    Spacer()
                        .frame(height: 2)

                    WithViewStore(store.viewAction, observe: \.selected.sourceId) { selectedSourceIdState in
                        WithViewStore(store.viewAction, observe: \.selected.serverId) { selectedServerIdState in
                            MoreListingRow(
                                title: "Servers",
                                selected: selectedServerIdState.state,
                                items: selectedSourceIdState.state.flatMap { sources[id: $0] }?.servers ?? [],
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

    @MainActor
    var speed: some View {
        EmptyView()
    }

    @MainActor
    var qualityAndSubtitles: some View {
        WithViewStore(store.viewAction) { state in
            state.selected.sourceId.flatMap { state.contents[sourceId: $0] } ?? .pending
        } content: { loadableServerResponseState in
            LoadableView(loadable: loadableServerResponseState.state) { response in
                VStack(alignment: .leading, spacing: 8) {
                    WithViewStore(store.viewAction, observe: \.selected.linkId) { selectedState in
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

                    WithViewStore(store.viewAction, observe: \.selected.subtitleId) { selectedIdState in
                        MoreListingRow(
                            title: "Subtitles",
                            selected: selectedIdState.state,
                            items: response.subtitles,
                            itemTitle: \.language
                        ) {
                        } selectedCallback: { _ in
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
    var settings: some View {
        EmptyView()
    }

    @MainActor
    private struct MoreListingRow<T: Identifiable>: View {
        var title: String
        var selected: T.ID?
        var items: [T]
        let itemTitle: KeyPath<T, String>
        var noneCallback: (() -> Void)?
        var selectedCallback: ((T.ID) -> Void)?

        private let textPadding = 12.0

        init(
            title: String,
            selected: T.ID? = nil,
            items: [T],
            itemTitle: KeyPath<T, String>,
            noneCallback: (() -> Void)? = nil,
            selectedCallback: ((T.ID) -> Void)? = nil
        ) {
            self.title = title
            self.selected = selected
            self.items = items
            self.itemTitle = itemTitle
            self.noneCallback = noneCallback
            self.selectedCallback = selectedCallback
        }

        @MainActor
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline.weight(.semibold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if items.isEmpty || noneCallback != nil {
                            Button {
                                noneCallback?()
                            } label: {
                                LazyHStack {
                                    if selected == nil || !items.contains(where: { $0.id == selected }) {
                                        Image(systemName: "checkmark")
                                    }
                                    Text("None")
                                }
                                .foregroundColor(.white)
                                .padding(textPadding)
                                .background(Color(white: 0.2))
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                                .fixedSize(horizontal: true, vertical: true)
                                .disabled(noneCallback == nil)
                            }
                        }

                        ForEach(items) { item in
                            Button {
                                selectedCallback?(item.id)
                            } label: {
                                LazyHStack(alignment: .center) {
                                    if selected == item.id {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(item[keyPath: itemTitle])
                                }
                                .foregroundColor(.white)
                                .padding(textPadding)
                                .background(Color(white: 0.2))
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                                .fixedSize(horizontal: true, vertical: true)
                            }
                        }
                    }
                }
                .font(.callout.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct VideoPlayerFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerFeature.View(
            store: .init(
                initialState: .init(
                    repoModuleID: .init(
                        repoId: .init(
                            .init(string: "/")
                                .unsafelyUnwrapped
                        ),
                        moduleId: ""
                    ),
                    playlist: .init(id: "0", type: .video),
                    contents: .init(
                        allGroups: .pending,
                        groups: [:],
                        sources: ["0": .loaded([])],
                        servers: ["0": .loaded(
                            .init(
                                links: [],
                                subtitles: []
                            )
                        )]
                    ),
                    selected: .init(groupId: 0, episodeId: "0", sourceId: "0", serverId: "0"),
                    overlay: .more(.qualityAndSubtitles)
                ),
                reducer: EmptyReducer()
            )
        )
        .previewInterfaceOrientation(.landscapeRight)
    }
}
#endif
