//
//  RepoPackagesFeature.swift
//
//
//  Created ErrorErrorError on 5/4/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import ModuleClient
import RepoClient
import Semver
import SharedModels
import Styling
import SwiftUI
import Tagged
import ViewComponents

// MARK: - RepoPackagesFeature

public struct RepoPackagesFeature: Feature {
  @Dependency(\.dismiss) var dismiss

  @Dependency(\.moduleClient) var moduleClient

  @Dependency(\.repoClient) var repoClient

  public init() {}
}

// MARK: - RepoPackagesFeature + State & Action

extension RepoPackagesFeature {
  public typealias Package = [Module.Manifest]

  public struct State: FeatureState {
    public var repo: Repo
    public var fetchedModules: Loadable<[Module.Manifest]>
    public var downloadStates: [Module.ID: RepoClient.RepoModuleDownloadState]
    public var packages: Loadable<[Package]>

    public var installedModules: [Module] {
      repo.modules.sorted(by: \.installDate)
    }

    public init(
      repo: Repo,
      fetchedModules: Loadable<[Module.Manifest]> = .pending,
      installingModules: [Module.ID: RepoClient.RepoModuleDownloadState] = [:],
      packages: Loadable<[Package]> = .pending
    ) {
      self.repo = repo
      self.fetchedModules = fetchedModules
      self.downloadStates = installingModules
      self.packages = packages
    }
  }

  public enum Action: FeatureAction {
    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)

    @CasePathable
    public enum ViewAction: SendableAction {
      case onTask
      case didTapClose
      case didTapToRefreshRepo
      case didTapAddModule(Module.ID)
      case didTapRemoveModule(Module.ID)
    }

    @CasePathable
    public enum InternalAction: SendableAction {
      case delayDeletingModule(id: Module.ID)
      case updateRepo(Repo?)
      case repoModules(Loadable<[Module.Manifest]>)
      case downloadStates([Module.ID: RepoClient.RepoModuleDownloadState])
    }

    @CasePathable
    public enum DelegateAction: SendableAction {}
  }
}

// MARK: RepoPackagesFeature.View

extension RepoPackagesFeature {
  @MainActor
  public struct View: FeatureView {
    public let store: StoreOf<RepoPackagesFeature>

    @Environment(\.theme) var theme

    @MainActor
    public init(store: StoreOf<RepoPackagesFeature>) {
      self.store = store
    }
  }
}

extension RepoPackagesFeature.Package {
  var latestModule: Module.Manifest {
    self.max { $0.version < $1.version }.unsafelyUnwrapped
  }
}
