//
//  SettingsFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/7/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture
import SharedModels

extension SettingsFeature.Reducer: ReducerProtocol {
    public typealias State = SettingsFeature.State
    public typealias Action = SettingsFeature.Action

    public var body: some ReducerProtocolOf<Self> {
        Reduce(self.core)
    }
}

extension SettingsFeature.Reducer {
    func core(state: inout State, action: Action) -> Effect<Action> {
        .none
    }
}
