//
//  HomeFeature+Reducer.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import ComposableArchitecture

extension HomeFeature.Reducer: ReducerProtocol {
    public typealias State = HomeFeature.State
    public typealias Action = HomeFeature.Action

    public var body: some ReducerProtocolOf<Self> {
        Reduce(self.core)
    }
}

extension HomeFeature.Reducer {
    func core(state: inout State, action: Action) -> Effect<Action> {
        .none
    }
}
