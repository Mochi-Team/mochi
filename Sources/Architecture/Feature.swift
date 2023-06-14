//
//  Feature.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import ComposableArchitecture
import Foundation
@_exported import FoundationHelpers
import SwiftUI

// MARK: - SendableAction

public protocol SendableAction: Equatable, Sendable {}

// MARK: - FeatureState

public protocol FeatureState: Equatable, Sendable {}

// MARK: - FeatureAction

public protocol FeatureAction: Equatable, Sendable {
    associatedtype ViewAction: SendableAction
    associatedtype DelegateAction: SendableAction
    associatedtype InternalAction: SendableAction

    /// ViewActions should be a description of what already happened,
    /// not what it needs to do.
    ///
    static func view(_: ViewAction) -> Self

    /// DelegateActions can send action back to parent reducer.
    ///
    static func delegate(_: DelegateAction) -> Self

    /// InternalActions should only be invoked within the same reducer calls.
    /// The only exception to that are accessing delegate actions.
    ///
    static func `internal`(_: InternalAction) -> Self
}

// MARK: - FeatureView

public protocol FeatureView: View {
    associatedtype State: FeatureState
    associatedtype Action: FeatureAction
    var store: Store<State, Action> { get }

    init(store: Store<State, Action>)
}

// MARK: - FeatureReducer

public protocol FeatureReducer: Reducer {
    associatedtype State
    associatedtype Action

    init()
}

// MARK: - Feature

public protocol Feature {
    associatedtype State: FeatureState
    associatedtype Action: FeatureAction
    associatedtype View: FeatureView
    associatedtype Reducer: FeatureReducer
}

public typealias FeatureStoreOf<F: Feature> = StoreOf<F.Reducer>
