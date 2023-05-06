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

public extension Equatable {
    var `self`: Self {
        get { self }
        set { self = newValue }
    }
}

public extension Store {
    func scope<ChildState, ChildAction>(
        state toChildState: @escaping (State) -> ChildState,
        action fromChildAction: @escaping (ChildAction) -> Action.InternalAction
    ) -> Store<ChildState, ChildAction> where Action: FeatureAction {
        self.scope(state: toChildState) { action in
            .internal(fromChildAction(action))
        }
    }
}

public extension Store where Action: FeatureAction {
    var viewAction: Store<State, Action.ViewAction> {
        self.scope(state: { $0 }, action: { .view($0) })
    }

    var internalAction: Store<State, Action.InternalAction> {
        self.scope(state: { $0 }, action: { .internal($0) })
    }
}

public extension Scope where ParentAction: FeatureAction {
    init<ChildState, ChildAction>(
        state toChildState: CasePath<ParentState, ChildState>,
        action toChildAction: CasePath<ParentAction.InternalAction, ChildAction>,
        @ReducerBuilder<ChildState, ChildAction> child: () -> Child
    ) where ChildState == Child.State, ChildAction == Child.Action {
        // swiftlint:disable operator_usage_whitespace
        self.init(
            state: toChildState,
            action: /ParentAction.internal..toChildAction,
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
        // swiftlint:disable operator_usage_whitespace
        self.init(
            state: toChildState,
            action: /ParentAction.internal..toChildAction,
            child: child
        )
    }
}

public extension Reduce where Action: FeatureAction {
    func ifLet<DestinationState, DestinationAction, Destination: Reducer>(
        _ toPresentationState: WritableKeyPath<State, PresentationState<DestinationState>>,
        action toPresentationAction: CasePath<Action.InternalAction, PresentationAction<DestinationAction>>,
        @ReducerBuilder<DestinationState, DestinationAction> then destination: () -> Destination
    ) -> _PresentationReducer<Self, Destination> where Destination.State == DestinationState, Destination.Action == DestinationAction {
        // swiftlint:disable operator_usage_whitespace
        self.ifLet(
            toPresentationState,
            action: /Action.internal..toPresentationAction,
            then: destination
        )
    }
}

extension PresentationState: @unchecked Sendable where State: Sendable {}

extension BindingAction: @unchecked Sendable where Root: Sendable {}

public extension Effect where Failure == Never {
    static func action(
        _ action: Action,
        animation: Animation? = nil
    ) -> Self {
        self.run { await $0(action, animation: animation) }
    }

    static func run(
        animation: Animation? = nil,
        _ operation: @escaping () async throws -> Action
    ) -> Self {
        self.run { try await $0(operation(), animation: animation) }
    }

    static func run(
        animation: Animation? = nil,
        _ operation: @escaping () async throws -> Void
    ) -> Self {
        self.run { _ in try await operation() }
    }
}

public extension ViewStore {
    func binding<ParentState, Value>(
        _ parentKeyPath: WritableKeyPath<ParentState, BindingState<Value>>,
        as keyPath: KeyPath<ViewState, Value>
    ) -> Binding<Value> where ViewAction: BindableAction, ViewAction.State == ParentState, Value: Equatable {
        self.binding(
            get: { $0[keyPath: keyPath] },
            send: { .binding(.set(parentKeyPath, $0)) }
        )
    }
}

/// Case reducer for handling view, internal, and delegate actions
/// in a reducer, specifically pullback
///
public struct Case<ParentState, ParentAction, Child: Reducer>: Reducer where Child.State == ParentState {
    public let toChildAction: CasePath<ParentAction, Child.Action>
    public let child: Child

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
    ) -> EffectTask<ParentAction> {
        guard let childAction = self.toChildAction.extract(from: action)
        else { return .none }
        return self.child
            .reduce(into: &state, action: childAction)
            .map(self.toChildAction.embed)
    }
}
