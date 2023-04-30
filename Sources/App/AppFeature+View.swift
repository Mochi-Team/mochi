//
//  AppFeature+View.swift
//  
//
//  Created by ErrorErrorError on 4/6/23.
//  
//

import Architecture
import ComposableArchitecture
import Foundation
import Home
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
                switch viewStore.state {
                case .home:
                    HomeFeature.View(
                        store: store.internalAction.scope(
                            state: \.home,
                            action: Action.InternalAction.home
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
            .inset(
                for: \.tabNavigation,
                alignment: .bottom,
                navbar(viewStore.state)
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheetView(
            store: store.internalAction.scope(
                state: \.$destination,
                action: Action.InternalAction.destination
            ),
            state: /AppFeature.Destination.State.sheet,
            action: AppFeature.Destination.Action.sheet
        ) { store in
            SwitchStore(store) { state in
                switch state {
                case .moduleLists:
                    CaseLet(
                        state: /AppFeature.Destination.State.Sheet.moduleLists,
                        action: AppFeature.Destination.Action.Sheet.moduleLists,
                        then: ModuleListsFeature.View.init(store:)
                    )
                }
            }
        }
        .popupView(
            store: store.internalAction.scope(
                state: \.$destination,
                action: Action.InternalAction.destination
            ),
            state: /AppFeature.Destination.State.popup,
            action: AppFeature.Destination.Action.popup
        ) { store in
            SwitchStore(store) { _ in }
        }
    }
}

extension AppFeature.View {
    @MainActor
    func navbar(_ selected: Self.State.Tab) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(State.Tab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 2) {
                    Image(systemName: tab == selected ? tab.selected : tab.image)
                        .font(.system(size: 20, weight: .semibold))

                    Text(tab.rawValue)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(tab == selected ? nil : .gray)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    ViewStore(store.viewAction.stateless).send(.didSelectTab(tab))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            BlurView()
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
        )
        .frame(
            maxWidth: .infinity,
            alignment: .bottom
        )
        .overlay(alignment: .top) {
            Color.gray.opacity(0.2)
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
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
