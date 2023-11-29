//
//  SettingsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import UserSettingsClient

public extension SettingsFeature {
    @ReducerBuilder<State, Action>
    var body: some ReducerOf<Self> {
        Scope(state: \.self, action: \.view) {
            BindingReducer()
                .onChange(of: \.userSettings) { _, userSettings in
                    Reduce { _, _ in
                        .run { await userSettingsClient.set(userSettings) }
                    }
                }
        }

        Reduce { _, action in
            switch action {
            case let .view(viewAction):
                switch viewAction {
                case .onTask:
                    break
                case .binding:
                    break
                }
            case .internal:
                break
            }
            return .none
        }
        .forEach(\.path, action: \.internal.path) {
            Path()
        }
    }
}
