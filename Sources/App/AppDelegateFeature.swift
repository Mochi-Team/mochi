//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Foundation
import ModuleClient
import SharedModels
import SwiftUI

public enum AppDelegateFeature {
    public typealias State = UserSettings

    public enum Action: SendableAction {
        case didFinishLaunching
    }

    public struct Reducer: ComposableArchitecture.Reducer {
        public typealias State = AppDelegateFeature.State
        public typealias Action = AppDelegateFeature.Action

        @Dependency(\.databaseClient)
        var databaseClient

        @Dependency(\.moduleClient)
        var moduleClient

        public init() {}

        public var body: some ComposableArchitecture.Reducer<State, Action> {
            Reduce { _, action in
                switch action {
                case .didFinishLaunching:
                    return .merge(
                        .run {
                            try await databaseClient.initialize()
                        },
                        .run {
                            try await moduleClient.initialize()
                        }
                    )
                }
            }
        }
    }
}
