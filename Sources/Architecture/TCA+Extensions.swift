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

public extension Scope where ParentAction: FeatureAction {
    init<ChildState, ChildAction>(
        state toChildState: CasePath<ParentState, ChildState>,
        action toChildAction: CasePath<ParentAction.InternalAction, ChildAction>,
        @ReducerBuilder<ChildState, ChildAction> child: () -> Child
    ) where ChildState == Child.State, ChildAction == Child.Action {
        self.init(
            state: toChildState,
            action: /ParentAction.internal .. toChildAction,
            child: child
        )
    }
}

public extension Scope where ParentAction: FeatureAction {
    init<ChildState, ChildAction>(
        state toChildState: WritableKeyPath<ParentState, ChildState>,
        action toChildAction: CasePath<ParentAction.InternalAction, ChildAction>,
        @ReducerBuilder<ChildState, ChildAction> child: () -> Child
    ) where ChildState == Child.State, ChildAction == Child.Action {
        self.init(
            state: toChildState,
            action: /ParentAction.internal .. toChildAction,
            child: child
        )
    }
}

public extension Reducer where Action: FeatureAction {
    func ifLet<DestinationState, DestinationAction, Destination: Reducer>(
        _ toPresentationState: WritableKeyPath<State, PresentationState<DestinationState>>,
        action toPresentationAction: CasePath<Action.InternalAction, PresentationAction<DestinationAction>>,
        @ReducerBuilder<DestinationState, DestinationAction> destination: () -> Destination
    ) -> _PresentationReducer<Self, Destination> where Destination.State == DestinationState, Destination.Action == DestinationAction {
        self.ifLet(
            toPresentationState,
            action: /Action.internal .. toPresentationAction,
            destination: destination
        )
    }

    func ifLet<WrappedState, WrappedAction, Wrapped: Reducer>(
        _ toWrappedState: WritableKeyPath<State, WrappedState?>,
        action toWrappedAction: CasePath<Action.InternalAction, WrappedAction>,
        @ReducerBuilder<WrappedState, WrappedAction> then wrapped: () -> Wrapped
    ) -> _IfLetReducer<Self, Wrapped> where WrappedState == Wrapped.State, WrappedAction == Wrapped.Action {
        self.ifLet(
            toWrappedState,
            action: /Action.internal .. toWrappedAction,
            then: wrapped
        )
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
        animation: Animation? = nil,
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
    public let toChildAction: CasePath<ParentAction, Child.Action>
    public let child: Child

    // swiftformat:disable opaqueGenericParameters
    @inlinable
    public init<ChildAction>(
        _ toChildAction: CasePath<ParentAction, ChildAction>,
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
