//
//  VideoPlayerFeature+Reducer.swift
//  
//
//  Created ErrorErrorError on 5/26/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture

extension VideoPlayerFeature.Reducer: Reducer {
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
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
