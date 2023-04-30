//
//  SearchFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

extension SearchFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: /State.self, action: /Action.view) {
            BindingReducer()
        }
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                break

            case .view(.didClearQuery):
                state.query = ""

            case .view(.binding):
                break

            case .internal:
                break

            case .delegate:
                break
            }
            return .none
        }
    }
}
