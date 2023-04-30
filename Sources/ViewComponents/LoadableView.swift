//
//  File.swift
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
public struct LoadableView<T, E, Loaded: View, Failed: View, Loading: View>: View {
    let loadable: Loadable<T, E>
    let loadedView: (T) -> Loaded
    let failedView: (E) -> Failed
    let loadingView: () -> Loading

    var asGroup = true

    public init(
        loadable: Loadable<T, E>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded,
        @ViewBuilder failedView: @escaping (E) -> Failed,
        @ViewBuilder loadingView: @escaping () -> Loading
    ) {
        self.loadable = loadable
        self.loadedView = loadedView
        self.failedView = failedView
        self.loadingView = loadingView
    }

    @MainActor
    public var body: some View {
        switch loadable {
        case .loading:
            loadingView()
        case let .loaded(t):
            loadedView(t)
        case let .failed(e):
            failedView(e)
        }
    }
}

public extension LoadableView {
    func asGroup(_ group: Bool) -> Self {
        var view = self
        view.asGroup = group
        return view
    }
}

public extension LoadableView {
    init(
        loadable: Loadable<T, E>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded
    ) where Loading == EmptyView, Failed == EmptyView {
        self.init(
            loadable: loadable,
            loadedView: loadedView,
            failedView: { _ in EmptyView() },
            loadingView: { EmptyView() }
        )
    }

    init(
        loadable: Loadable<T, E>,
        @ViewBuilder loadedView: @escaping (T) -> Loaded,
        @ViewBuilder failedView: @escaping (E) -> Failed
    ) where Loading == EmptyView {
        self.init(
            loadable: loadable,
            loadedView: loadedView,
            failedView: failedView
        ) {
            EmptyView()
        }
    }
}

// MARK: - LoadableStore

public struct LoadableStore<T, E, Action, Loaded: View, Failed: View, Loading: View>: View {
    let store: Store<Loadable<T, E>, Action>
    let loadedView: (Store<T, Action>) -> Loaded
    let failedView: (Store<E, Action>) -> Failed
    let loadingView: (Store<Void, Action>) -> Loading

    public init(
        store: Store<Loadable<T, E>, Action>,
        @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded,
        @ViewBuilder failedView: @escaping (Store<E, Action>) -> Failed,
        @ViewBuilder loadingView: @escaping (Store<Void, Action>) -> Loading
    ) {
        self.store = store
        self.loadedView = loadedView
        self.failedView = failedView
        self.loadingView = loadingView
    }

    public var body: some View {
        EmptyView()
        SwitchStore(store) {
            CaseLet(state: /Loadable<T, E>.loaded, then: loadedView)
            CaseLet(state: /Loadable<T, E>.failed, then: failedView)
            CaseLet(state: /Loadable<T, E>.loading, then: loadingView)
        }
    }
}

public extension LoadableStore where Loading == EmptyView, Failed == EmptyView {
    init(
        store: Store<Loadable<T, E>, Action>,
        @ViewBuilder loadedView: @escaping (Store<T, Action>) -> Loaded
    ) {
        self.store = store
        self.loadedView = loadedView
        self.failedView = { _ in EmptyView() }
        self.loadingView = { _ in EmptyView() }
    }
}
