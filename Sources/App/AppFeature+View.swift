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
import ModuleLists
import Repos
import Search
import Settings
import Styling
import SwiftUI
import ViewComponents

extension AppFeature.View: View {
    @MainActor
    public var body: some View {
        WithViewStore(
            store.viewAction,
            observe: \.selected
        ) { viewStore in
            ZStack {
                Group {
                    switch viewStore.state {
                    case .discover:
                        DiscoverFeature.View(
                            store: store.internalAction.scope(
                                state: \.discover,
                                action: Action.InternalAction.discover
                            )
                        )
                    case .repos:
                        ReposFeature.View(
                            store: store.internalAction.scope(
                                state: \.repos,
                                action: Action.InternalAction.repos
                            )
                        )
                    case .search:
                        SearchFeature.View(
                            store: store.internalAction.scope(
                                state: \.search,
                                action: Action.InternalAction.search
                            )
                        )
                    case .settings:
                        SettingsFeature.View(
                            store: store.internalAction.scope(
                                state: \.settings,
                                action: Action.InternalAction.settings
                            )
                        )
                    }
                }
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.2), value: viewStore.state)
            .safeAreaInset(edge: .bottom) {
                navbar(viewStore.state)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            ViewStore(store.viewAction.stateless).send(.didAppear)
        }
    }
}

extension AppFeature.View {
    @MainActor
    func navbar(_ selected: Self.State.Tab) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(State.Tab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 2) {
                    if tab == selected {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: 18, height: 4)
                            .transition(.opacity.combined(with: .scale))
                    }

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
                .contentShape(Rectangle())
                .onTapGesture {
                    ViewStore(store.viewAction.stateless).send(.didSelectTab(tab))
                }
                .background(
                    Rectangle()
                        .foregroundColor(tab.colorAccent.opacity(tab == selected ? 0.08 : 0.0))
                        .ignoresSafeArea(.all)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 24)
                )
                .animation(.easeInOut(duration: 0.2), value: tab == selected)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(
            maxWidth: .infinity,
            alignment: .bottom
        )
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

struct AppFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        AppFeature.View(
            store: .init(
                initialState: .init(),
                reducer: AppFeature.Reducer()
            )
        )
    }
}
