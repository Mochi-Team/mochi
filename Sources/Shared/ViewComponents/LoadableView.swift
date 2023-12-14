//
//  LoadableView.swift
//
//
//  Created by ErrorErrorError on 1/7/23.
//
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

// MARK: - LoadableView

@MainActor
public struct LoadableView<T, Loaded: View, Failed: View, Loading: View, Pending: View>: View {
  let loadable: Loadable<T>
  let loadedView: (T) -> Loaded
  let failedView: (Error) -> Failed
  let loadingView: () -> Loading
  let pendingView: () -> Pending

  public init(
    loadable: Loadable<T>,
    @ViewBuilder loadedView: @escaping (T) -> Loaded,
    @ViewBuilder failedView: @escaping (Error) -> Failed,
    @ViewBuilder loadingView: @escaping () -> Loading,
    @ViewBuilder pendingView: @escaping () -> Pending
  ) {
    self.loadable = loadable
    self.loadedView = loadedView
    self.failedView = failedView
    self.loadingView = loadingView
    self.pendingView = pendingView
  }

  @MainActor public var body: some View {
    switch loadable {
    case .pending:
      pendingView()
    case .loading:
      loadingView()
    case let .loaded(t):
      loadedView(t)
    case let .failed(e):
      failedView(e)
    }
  }
}

extension LoadableView {
  public init(
    loadable: Loadable<T>,
    @ViewBuilder loadedView: @escaping (T) -> Loaded
  ) where Loading == EmptyView, Failed == EmptyView, Pending == EmptyView {
    self.init(
      loadable: loadable,
      loadedView: loadedView,
      failedView: { _ in EmptyView() },
      loadingView: { EmptyView() },
      pendingView: { EmptyView() }
    )
  }

  public init(
    loadable: Loadable<T>,
    @ViewBuilder loadedView: @escaping (T) -> Loaded,
    @ViewBuilder failedView: @escaping (Error) -> Failed
  ) where Loading == EmptyView, Pending == EmptyView {
    self.init(
      loadable: loadable,
      loadedView: loadedView,
      failedView: failedView
    ) {
      EmptyView()
    } pendingView: {
      EmptyView()
    }
  }

  public init(
    loadable: Loadable<T>,
    @ViewBuilder loadedView: @escaping (T) -> Loaded,
    @ViewBuilder failedView: @escaping (Error) -> Failed,
    @ViewBuilder waitingView: @escaping () -> Loading
  ) where Loading == Pending {
    self.init(
      loadable: loadable,
      loadedView: loadedView,
      failedView: failedView,
      loadingView: waitingView,
      pendingView: waitingView
    )
  }
}

// MARK: - LoadableStore

public struct LoadableStore<T, Action, Loaded: View, Failed: View, Loading: View, Pending: View>: View {
  let store: Store<Loadable<T>, Action>
  let loadedView: (Store<T, Action>) -> Loaded
  let failedView: (Store<Error, Action>) -> Failed
  let loadingView: (Store<Void, Action>) -> Loading
  let pendingView: (Store<Void, Action>) -> Pending

  public init(
    store: Store<Loadable<T>, Action>,
    @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded,
    @ViewBuilder failedView: @escaping (Store<Error, Action>) -> Failed,
    @ViewBuilder loadingView: @escaping (Store<Void, Action>) -> Loading,
    @ViewBuilder pendingView: @escaping (Store<Void, Action>) -> Pending
  ) {
    self.store = store
    self.loadedView = loadedView
    self.failedView = failedView
    self.loadingView = loadingView
    self.pendingView = pendingView
  }

  public var body: some View {
    SwitchStore(store) { state in
      switch state {
      case .loaded:
        CaseLet(state: /Loadable<T>.loaded, then: loadedView)
      case .failed:
        CaseLet(state: /Loadable<T>.failed, then: failedView)
      case .loading:
        CaseLet(state: /Loadable<T>.loading, then: loadingView)
      case .pending:
        CaseLet(state: /Loadable<T>.pending, then: pendingView)
      }
    }
  }
}

extension LoadableStore where Loading == EmptyView, Failed == EmptyView, Pending == EmptyView {
  public init(
    store: Store<Loadable<T>, Action>,
    @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded
  ) {
    self.store = store
    self.loadedView = loadedView
    self.failedView = { _ in EmptyView() }
    self.loadingView = { _ in EmptyView() }
    self.pendingView = { _ in EmptyView() }
  }
}
