//
//  PlaylistDetailsFeature+View+iOS.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

// #if os(iOS)
import Architecture
import ComposableArchitecture
import ContentCore
import ModuleClient
import NukeUI
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - PlaylistDetailsFeature.View + View

extension PlaylistDetailsFeature.View: View {
  @MainActor public var body: some View {
    WithViewStore(store, observe: \.playlistInfo) { viewStore in
      ZStack {
        if viewStore.error != nil {
          VStack(spacing: 14) {
            Text("Failed to retrieve contents.")
              .font(.callout.bold())
              .contrast(0.75)

            Button {
              viewStore.send(.didTapToRetryDetails)
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
            color: imageDominatColor ?? theme.backgroundColor,
            location: 0
          ),
          .init(
            color: theme.backgroundColor,
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
    #if os(iOS)
      .navigationBarTitle("", displayMode: .inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {} label: {
            Image(systemName: "plus")
          }
          .buttonStyle(.materialToolbarItem)
          .disabled(true)
        }

        ToolbarItem(placement: .topBarTrailing) {
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
              .materialToolbarItemStyle()
          }
        }
      }
    #elseif os(macOS)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button {} label: {
            Image(systemName: "plus")
          }
          .disabled(true)
        }

        ToolbarItem(placement: .automatic) {
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
        }
      }
    #endif
      .initialTask {
        _ = await MainActor.run {
          store.send(.view(.onTask))
        }
      }
      .sheet(
        store: store.scope(
          state: \.$destination,
          action: \.internal.destination
        ),
        state: /PlaylistDetailsFeature.Destination.State.readMore,
        action: PlaylistDetailsFeature.Destination.Action.readMore
      ) { store in
        WithViewStore(store, observe: \.`self`) { viewStore in
          ScrollView(.vertical) {
            Text(viewStore.description)
              .foregroundColor(theme.textColor)
              .padding()
          }
          .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
            VStack(spacing: 0) {
              Text(viewStore.title)
                .lineLimit(1)
                .font(.body.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
              Divider()
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
        let readableColor = readableColor.isDark ? Color.white : Color.black
        LinearGradient(
          gradient: .init(
            colors: [
              readableColor.opacity(0),
              (imageDominatColor ?? readableColor).opacity(0.4)
            ],
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
            if case let .resume(_, _, _, _, title, progress) = viewStore.state {
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
              if let action = viewStore.state.action {
                viewStore.send(action)
              }
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
            .disabled(viewStore.state.action == nil)
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
        ExpandableText(playlistInfo.synopsis ?? "Description is not available for this content.") {
          store.send(.view(.didTapOnReadMore))
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

      if playlistInfo.status != .upcoming {
        ContentCore.View(
          store: store.scope(
            state: \.content,
            action: \.internal.content
          ),
          contentType: playlistInfo.type
        )
      }
    }
  }
}

// MARK: - HeaderWithContent

@MainActor
private struct HeaderWithContent<Label: View, Content: View>: View {
  let label: () -> Label
  let content: () -> Content

  @MainActor var body: some View {
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
  @MainActor var dotSpaced: some View {
    Text("\u{2022}")
  }

  @MainActor var readableColor: Color {
    imageDominatColor?.isDark ?? true ? .white : .black
  }
}

// MARK: - PlaylistDetailsFeatureView_Previews

#Preview {
  PlaylistDetailsFeature.View(
    store: .init(
      initialState: .init(
        content: .init(
          repoModuleId: Module().id(repoID: "/"),
          playlist: .placeholder(0)
        ),
        details: .loaded(
          .init(
            genres: ["Action", "Thriller"],
            yearReleased: 2_023,
            previews: .init()
          )
        ),
        destination: nil
      ),
      reducer: { EmptyReducer() }
    )
  )
}

// #endif
