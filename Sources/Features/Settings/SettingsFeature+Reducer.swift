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
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
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
}
