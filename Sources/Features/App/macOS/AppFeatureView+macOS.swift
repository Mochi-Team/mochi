//
//  AppFeatureView+macOS.swift
//
//
//  Created by ErrorErrorError on 11/23/23.
//
//

import Architecture
import ComposableArchitecture
import Discover
import Foundation
import Repos
import Styling
import SwiftUI
import VideoPlayer

#if os(macOS)
extension AppFeature.View: View {
  @MainActor public var body: some View {
    NavigationView {
      WithViewStore(store, observe: \.selected) { viewStore in
        List {
          ForEach(State.Tab.allCases.filter(\.self != .settings), id: \.rawValue) { tab in
            NavigationLink(
              tag: tab,
              selection: viewStore.binding(
                get: { tab == $0 ? tab : nil },
                send: .view(.didSelectTab(tab))
              )
            ) {
              Group {
                switch tab {
                case .discover:
                  DiscoverFeature.View(
                    store: store.scope(
                      state: \.discover,
                      action: \.internal.discover
                    )
                  )
                case .repos:
                  ReposFeature.View(
                    store: store.scope(
                      state: \.repos,
                      action: \.internal.repos
                    )
                  )
                case .settings:
                  EmptyView()
                }
              }
              // FIXME: Set max width for inside scroll view to show scrollbar to the edge
              .frame(maxWidth: 1_280)
            } label: {
              Label(tab.localized, systemImage: tab.image)
            }
          }
        }
        .listStyle(.sidebar)
      }

      Text("")
    }
    .window(
      store: store.scope(
        state: \.$videoPlayer,
        action: \.internal.videoPlayer
      ),
      content: VideoPlayerFeature.View.init
    )
  }
}
#endif
