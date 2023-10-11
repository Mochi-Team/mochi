//
//  SettingsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

extension SettingsFeature {
    @ReducerBuilder<State, Action>
    public var body: some ReducerOf<Self> {
        Scope(state: /State.self, action: /Action.view) {
            BindingReducer()
                .onChange(of: \.userSettings) { _, userSettings in
                    Reduce { _, _ in
                        enum CancelID { case saveDebounce }
                        return .run { _ in await userSettingsClient.set(userSettings) }
                            .debounce(id: CancelID.saveDebounce, for: .seconds(0.5), scheduler: mainQueue)
                    }
                }
        }

        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                switch viewAction {
                case .didAppear:
                    break
                case .binding:
                    break
                }
            }
            return .none
        }
    }
}
