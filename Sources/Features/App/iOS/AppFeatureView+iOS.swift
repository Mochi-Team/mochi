//
//  AppFeatureView+iOS.swift
//
//
//  Created by ErrorErrorError on 11/23/23.
//
//

import Architecture
import ComposableArchitecture
import Discover
import Foundation
import FoundationHelpers
import ModuleLists
import Repos
import Settings
import Styling
import SwiftUI
import VideoPlayer
import ViewComponents

#if os(iOS)
extension AppFeature.View: View {
  @MainActor
  public var body: some View {
    WithViewStore(store, observe: \.selected) { viewStore in
      TabView(
        selection: viewStore.binding(
          get: \.`self`,
          send: { .didSelectTab($0) }
        )
      ) {
        ForEach(Self.State.Tab.allCases, id: \.self) { (tab: Self.State.Tab) in
          Group {
            switch tab {
            case .discover:
              DiscoverFeature.View(
                store: store.scope(
                  state: \.discover,
                  action: \.internal.discover
                )
              )
              .tint(nil)
            case .repos:
              ReposFeature.View(
                store: store.scope(
                  state: \.repos,
                  action: \.internal.repos
                )
              )
              .tint(nil)
            case .settings:
              SettingsFeature.View(
                store: store.scope(
                  state: \.settings,
                  action: \.internal.settings
                )
              )
              .tint(nil)
            }
          }
          .tabItem {
            Label(tab.localized, systemImage: viewStore.state == tab ? tab.selected : tab.image)
          }
          .tag(tab)
        }
      }
      // Set tint of tab item
      .tint(viewStore.state.colorAccent)
    }
    .onAppear { store.send(.view(.didAppear)) }
    .overlay {
      WithViewStore(store, observe: \.videoPlayer != nil) { isVisible in
        IfLetStore(
          store.scope(
            state: \.$videoPlayer,
            action: \.internal.videoPlayer
          ),
          then: { VideoPlayerFeature.View(store: $0) }
        )
        .blur(radius: isVisible.state ? 0.0 : 30)
        .opacity(isVisible.state ? 1.0 : 0.0)
        .animation(.easeInOut, value: isVisible.state)
      }
    }
    .themeable()
  }
}

#Preview {
  AppFeature.View(
    store: .init(
      initialState: .init(selected: .settings),
      reducer: { AppFeature() }
    )
  )
}
#endif
