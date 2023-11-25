//
//  TCA+Extensions.swift
//
//
//  Created by ErrorErrorError on 4/7/23.
//
//

import ComposableArchitecture
import Foundation
import SwiftUI

public extension Store where Action: FeatureAction {
    func scope<ChildState, ChildAction>(
        state toChildState: @escaping (State) -> ChildState,
        action fromChildAction: @escaping (ChildAction) -> Action.ViewAction
    ) -> Store<ChildState, ChildAction> {
        scope(state: toChildState) { .view(fromChildAction($0)) }
    }

    func scope<ChildState, ChildAction>(
        state toChildState: @escaping (State) -> ChildState,
        action fromChildAction: @escaping (ChildAction) -> Action.InternalAction
    ) -> Store<ChildState, ChildAction> {
        scope(state: toChildState) { .internal(fromChildAction($0)) }
    }
}

public extension Effect {
    static func run(
        animation: Animation? = nil,
        _ operation: @escaping () async throws -> Action
    ) -> Self {
        run { try await $0(operation(), animation: animation) }
    }

    static func run(
        animation _: Animation? = nil,
        _ operation: @escaping () async throws -> Void
    ) -> Self {
        run { _ in try await operation() }
    }
}

// MARK: - Case

/// Case reducer for handling view, internal, and delegate actions
/// in a reducer, specifically pullback
///
public struct Case<ParentState, ParentAction, Child: Reducer>: Reducer where Child.State == ParentState {
    public let toChildAction: AnyCasePath<ParentAction, Child.Action>
    public let child: Child

    // swiftformat:disable opaqueGenericParameters
    @inlinable
    public init<ChildAction>(
        _ toChildAction: AnyCasePath<ParentAction, ChildAction>,
        @ReducerBuilder<Child.State, Child.Action> _ child: () -> Child
    ) where ChildAction == Child.Action {
        self.toChildAction = toChildAction
        self.child = child()
    }

    @inlinable
    public func reduce(
        into state: inout ParentState, action: ParentAction
    ) -> Effect<ParentAction> {
        guard let childAction = toChildAction.extract(from: action) else {
            return .none
        }
        return child
            .reduce(into: &state, action: childAction)
            .map(toChildAction.embed)
    }
}

public extension WithViewStore where ViewState: Equatable, Content: View {
    init<State, Action: FeatureAction>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (_ state: State) -> ViewState,
        @ViewBuilder content: @escaping (_ viewStore: ViewStore<ViewState, ViewAction>) -> Content
    ) where ViewAction == Action.ViewAction {
        self.init(
            store,
            observe: toViewState,
            send: Action.view,
            content: content
        )
    }

    init<State, Action: FeatureAction>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (_ state: BindingViewStore<State>) -> ViewState,
        @ViewBuilder content: @escaping (_ viewStore: ViewStore<ViewState, ViewAction>) -> Content
    ) where ViewAction == Action.ViewAction, ViewAction: BindableAction, ViewAction.State == State {
        self.init(
            store,
            observe: toViewState,
            send: Action.view,
            removeDuplicates: ==,
            content: content
        )
    }
}

public extension ViewStore where ViewState: Equatable {
    convenience init<State, Action: FeatureAction>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (_ state: State) -> ViewState
    ) where ViewAction == Action.ViewAction {
        self.init(
            store,
            observe: toViewState,
            send: Action.view,
            removeDuplicates: ==
        )
    }
}
