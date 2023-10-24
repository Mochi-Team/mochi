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
        Scope(state: /State.self, action: /Action.view) {
            BindingReducer()
                .onChange(of: \.userSettings) { _, userSettings in
                    Reduce { _, _ in
                        enum CancelID { case saveDebounce }
                        return .run { _ in
                            await userSettingsClient.set(userSettings)
                            try await withTaskCancellation(id: CancelID.saveDebounce) {
                                try await Task.sleep(nanoseconds: 500_000_000)
                            }
                        }
                    }
                }
        }

        Reduce { _, action in
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
