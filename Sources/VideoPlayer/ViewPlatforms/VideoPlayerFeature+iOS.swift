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
                    .animation(.easeInOut, value: viewStore.state == .none)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea(.all, edges: .all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
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
            controlsBar
            Spacer()
            bottomBar
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.black
                .opacity(0.2)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
        }
    }

    @MainActor
    var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                ViewStore(store.viewAction.stateless).send(.didTapBackButton)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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

            Button {} label: {
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
            min(1.0, max(0, viewStore.progress.seconds / viewStore.duration.seconds))
        }

        @SwiftUI.State
        private var dragProgress: Double?

        private var isDragging: Bool {
            dragProgress != nil
        }

        private var canUseControls: Bool {
            viewStore.duration.isValid && viewStore.duration != .zero
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
                        Text(viewStore.progress.displayTime ?? "00:00") +
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
    }
}

extension VideoPlayerFeature.View {
    private struct SplitListingsView<LeadingContents: View, TrailingContents: View>: View {
        let leadingContents: () -> LeadingContents
        let trailingContents: () -> TrailingContents

        var body: some View {
            GeometryReader { proxy in
                if proxy.size.width < proxy.size.height {
                    ScrollView {
                        VStack(spacing: 12) {
                            leadingContents()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            trailingContents()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        leadingContents()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        trailingContents()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

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
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea(.all, edges: .all)
        }
        .foregroundColor(.white)
    }

    @MainActor
    var episodes: some View {
        WithViewStore(store.viewAction, observe: \.contents.allGroups) { allGroupsStore in
            LoadableView(loadable: allGroupsStore.state) { allGroups in
                VStack(spacing: 0) {
                    WithViewStore(
                        store,
                        observe: \.selected.groupId
                    ) { selectedGroupStore in
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
                SplitListingsView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Sources")
                            .font(.title2.weight(.semibold))
                        Spacer()
                            .frame(height: 12)
                        Divider()
                        if !sources.isEmpty {
                            WithViewStore(store.viewAction, observe: \.selected.sourceId) { selectedSourceIdState in
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        Spacer()
                                            .frame(height: 12)

                                        ForEach(sources) { source in
                                            VStack(alignment: .leading) {
                                                Text(source.displayName)
                                                    .foregroundColor(selectedSourceIdState.state == source.id ? .white : .gray)
                                                if let description = source.description {
                                                    Text(description)
                                                        .font(.footnote)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedSourceIdState.send(.didTapSource(source.id))
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            Spacer()
                            Text("No Sources Available")
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } trailingContents: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Servers")
                            .font(.title2.weight(.semibold))
                        Spacer()
                            .frame(height: 12)
                        Divider()
                        WithViewStore(store) { state in
                            state.selected.sourceId.flatMap { id in
                                sources.first { $0.id == id }
                            }
                        } content: { selectedSourceState in
                            if let source = selectedSourceState.state {
                                WithViewStore(store.viewAction, observe: \.selected.serverId) { selectedServerIdState in
                                    ScrollView {
                                        VStack {
                                            Spacer()
                                                .frame(height: 12)

                                            ForEach(source.servers) { server in
                                                VStack(alignment: .leading) {
                                                    Text(server.displayName)
                                                        .foregroundColor(selectedServerIdState.state == server.id ? .white : .gray)

                                                    if let description = server.description {
                                                        Text(description)
                                                            .font(.footnote)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                .padding(12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedServerIdState.send(.didTapServer(server.id))
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            } else {
                                Spacer()
                                Text("No Servers Available")
                                Spacer()
                            }
                        }
                    }
                }
            } failedView: { _ in
                Text("Failed to load Sources.")
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
                SplitListingsView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Quality")
                            .font(.title2.weight(.semibold))
                        Spacer()
                            .frame(height: 12)
                        Divider()

                        if !response.links.isEmpty {
                            WithViewStore(store.viewAction, observe: \.selected.linkId) { selectedLinkIdState in
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        Spacer()
                                            .frame(height: 12)

                                        ForEach(response.links) { link in
                                            VStack(alignment: .leading) {
                                                Text(link.quality.description)
                                                    .foregroundColor(selectedLinkIdState.state == link.id ? .white : .gray)
                                            }
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedLinkIdState.send(.didTapLink(link.id))
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            Spacer()
                            Text("No Links Available")
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } trailingContents: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Subtitles")
                            .font(.title2.weight(.semibold))
                        Spacer()
                            .frame(height: 12)
                        Divider()

                        if !response.subtitles.isEmpty {
                            Text("Todo")
                        } else {
                            Spacer()
                            Text("No Subtitles Available")
                            Spacer()
                        }
                    }
                }
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
                        allGroups: .loaded([.init(id: 0)]),
                        groups: [0: .loading]
                    ),
                    groupId: 0,
                    episodeId: "",
                    overlay: .more(.episodes)
                ),
                reducer: VideoPlayerFeature.Reducer()
            )
        )
        .previewInterfaceOrientation(.landscapeRight)
    }
}
#endif
