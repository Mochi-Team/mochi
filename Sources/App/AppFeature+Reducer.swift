//
//  AppFeature+Reducer.swift
//  
//
//  Created by ErrorErrorError on 4/6/23.
//  
//

import ComposableArchitecture
import Home

extension AppFeature.Reducer: ReducerProtocol {
    public typealias State = AppFeature.State
    public typealias Action = AppFeature.Action

    public var body: some ReducerProtocolOf<Self> {
        Reduce(self.core)

//        Scope(state: /State.home, action: /Action.view) {
//            HomeFeature.Reducer()
//        }
    }
}

extension AppFeature.Reducer {
    func core(state: inout State, action: Action) -> Effect<Action> {
        .none
    }
}
