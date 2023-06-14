//
//  SettingsFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

// MARK: - SettingsFeature.Reducer + Reducer

extension SettingsFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce(self.core)
    }
}

extension SettingsFeature.Reducer {
    func core(state _: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .view(viewAction):
            switch viewAction {
            case .didAppear:
                break
            }
        }
        return .none
    }
}
