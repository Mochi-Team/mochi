//
//  LibraryFeature.swift
//
//
//  Created ErrorErrorError on 1/2/24.
//  Copyright © 2024. All rights reserved.
//

import Architecture
import ComposableArchitecture

public enum LibraryFeature: Feature {
  public struct State: FeatureState {
    // TODO: Set state

    public init() {}
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: FeatureAction {
    public enum ViewAction: SendableAction {}
    public enum DelegateAction: SendableAction {}
    public enum InternalAction: SendableAction {}

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<LibraryFeature>

    public nonisolated init(store: StoreOf<LibraryFeature>) {
      self.store = store
    }
  }

  public init() {}
}
