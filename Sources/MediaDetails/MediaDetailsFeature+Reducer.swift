//
//  MediaDetailsFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import ModuleClient
import SharedModels

extension MediaDetailsFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                break

            case .view(.didTappedBackButton):
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
