//
//  AppDelegateFeature.swift
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

@Reducer
public struct AppDelegateFeature: Reducer {
  public struct State: FeatureState {}

  @CasePathable
  public enum Action: SendableAction {
    case didFinishLaunching
  }

  @Dependency(\.databaseClient)
  var databaseClient

  @Dependency(\.moduleClient)
  var moduleClient

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .didFinishLaunching:
        .run { _ in
          try? await databaseClient.initialize()
          try? await moduleClient.initialize()
        }
      }
    }
  }
}
