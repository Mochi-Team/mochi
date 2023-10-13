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
            ZStack {
                switch viewStore.state {
                case .discover:
                    DiscoverFeature.View(
                        store: store.scope(
                            state: \.discover,
                            action: Action.InternalAction.discover
                        )
                    )
                case .repos:
                    ReposFeature.View(
                        store: store.scope(
                            state: \.repos,
                            action: Action.InternalAction.repos
                        )
                    )
                case .settings:
                    SettingsFeature.View(
                        store: store.scope(
                            state: \.settings,
                            action: Action.InternalAction.settings
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                navbar(viewStore.state)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
        }
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
        .themable()
    }
}

private struct CustomTabItemStyle: View {
    let tab: AppFeature.State.Tab

    var body: some View {
        Label(tab.rawValue, systemImage: tab.image)
    }
}

extension AppFeature.View {
    @MainActor
    func navbar(_ selected: Self.State.Tab) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(State.Tab.allCases, id: \.rawValue) { tab in
                Button {
                    store.send(.view(.didSelectTab(tab)))
                } label: {
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: tab == selected ? 18 : 0, height: 4)
                            .transition(.scale.combined(with: .opacity))
                            .opacity(tab == selected ? 1.0 : 0.0)

                        Image(systemName: tab == selected ? tab.selected : tab.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(height: 18)
                            .padding(.top, 8)

                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(tab == selected ? tab.colorAccent : .gray)
                    .frame(maxWidth: .infinity)
                    .background(
                        Rectangle()
                            .foregroundColor(tab.colorAccent.opacity(tab == selected ? 0.08 : 0.0))
                            .ignoresSafeArea(.all)
                            .edgesIgnoringSafeArea(.all)
                            .blur(radius: 24)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.scaled)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.2), value: tab == selected)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
        }
        .overlay(alignment: .top) {
            Color.gray.opacity(0.2)
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    AppFeature.View(
        store: .init(
            initialState: .init(),
            reducer: { AppFeature() }
        )
    )

}
