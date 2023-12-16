//
//  ReposFeature.swift
//
//
//  Created ErrorErrorError on 4/18/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ClipboardClient
import ComposableArchitecture
import Foundation
import ModuleClient
import RepoClient
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

public struct ReposFeature: Feature {
  public struct State: FeatureState {
    public var repos: IdentifiedArrayOf<Repo>
    @BindingState public var url: String
    public var searchedRepo: Loadable<RepoClient.RepoPayload>
    public var path: StackState<RepoPackagesFeature.State>

    public init(
      repos: IdentifiedArrayOf<Repo> = [],
      url: String = "",
      searchedRepo: Loadable<RepoClient.RepoPayload> = .pending,
      path: StackState<RepoPackagesFeature.State> = .init()
    ) {
      self.repos = repos
      self.url = url
      self.searchedRepo = searchedRepo
      self.path = path
    }
  }

  @CasePathable
  public enum Action: FeatureAction {
    @CasePathable
    public enum ViewAction: SendableAction, BindableAction {
      case onTask
      case didTapRepo(Repo.ID)
      case didTapAddNewRepo(RepoClient.RepoPayload)
      case didTapCopyRepoURL(Repo.ID)
      case didTapDeleteRepo(Repo.ID)
      case binding(BindingAction<State>)
    }

    @CasePathable
    public enum DelegateAction: SendableAction {}

    @CasePathable
    public enum InternalAction: SendableAction {
      case validateRepoURL(Loadable<RepoClient.RepoPayload>)
      case loadRepos([Repo])
      case path(StackAction<RepoPackagesFeature.State, RepoPackagesFeature.Action>)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
    case `internal`(InternalAction)
  }

  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<ReposFeature>

    @Environment(\.theme) var theme
    @Dependency(\.dateFormatter) var dateFormatter

    @MainActor
    public init(store: StoreOf<ReposFeature>) {
      self.store = store
    }
  }

  @Dependency(\.clipboardClient) var clipboardClient
  @Dependency(\.repoClient) var repoClient
  @Dependency(\.moduleClient) var moduleClient

  public init() {}
}
