//
//  AppFeature+View.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import ComposableArchitecture
import Discover
import Foundation
import FoundationHelpers
import ModuleLists
import Repos
import Search
import Settings
import Styling
import SwiftUI
import VideoPlayer
import ViewComponents

// MARK: - AppFeature.View + View

extension AppFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(store, observe: \.selected) { viewStore in
            TabView(selection: viewStore.binding(send: { .view(.didSelectTab($0)) })) {
                DiscoverFeature.View(
                    store: store.scope(
                        state: \.discover,
                        action: Action.InternalAction.discover
                    )
                )
                .tabItem { CustomTabItemStyle(tab: .discover) }
                .tag(AppFeature.State.Tab.discover)

                ReposFeature.View(
                    store: store.scope(
                        state: \.repos,
                        action: Action.InternalAction.repos
                    )
                )
                .tabItem { CustomTabItemStyle(tab: .repos) }
                .tag(AppFeature.State.Tab.repos)

                SettingsFeature.View(
                    store: store.scope(
                        state: \.settings,
                        action: Action.InternalAction.settings
                    )
                )
                .tabItem { CustomTabItemStyle(tab: .settings) }
                .tag(AppFeature.State.Tab.settings)
            }
            .tint(viewStore.state.colorAccent)
        }
        .background(
            Color.theme.backgroundColor
                .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
        )
        .onAppear {
            store.send(.view(.didAppear))
        }
        .overlay {
            WithViewStore(store, observe: \.videoPlayer != nil) { isVisible in
                IfLetStore(
                    store.scope(
                        state: \.$videoPlayer,
                        action: { .internal(.videoPlayer($0)) }
                    ),
                    then: VideoPlayerFeature.View.init
                )
                .blur(radius: isVisible.state ? 0.0 : 30)
                .opacity(isVisible.state ? 1.0 : 0.0)
                .animation(.easeInOut, value: isVisible.state)
            }
        }
    }
}

private struct CustomTabItemStyle: View {
    let tab: AppFeature.State.Tab

    var body: some View {
        Label(tab.rawValue, systemImage: tab.image)
    }
}

// MARK: - AppFeatureView_Previews

struct AppFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        AppFeature.View(
            store: .init(
                initialState: .init(),
                reducer: { AppFeature() }
            )
        )
    }
}
