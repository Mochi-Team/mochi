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

// MARK: - Feature

public protocol Feature: Reducer where State: FeatureState, Action: FeatureAction {
    associatedtype View: FeatureView
}

// MARK: - SendableAction

public protocol SendableAction: Equatable, Sendable {}

// MARK: - FeatureState

public protocol FeatureState: Equatable, Sendable {}

// MARK: - FeatureAction

public protocol FeatureAction: Equatable, Sendable {
    associatedtype ViewAction: SendableAction
    associatedtype DelegateAction: SendableAction
    associatedtype InternalAction: SendableAction

    /// ViewActions is a description of what already happened,
    /// not what it needs to do.
    ///
    static func view(_: ViewAction) -> Self

    /// DelegateActions are actions that should be sent back to parent reducer.
    ///
    static func delegate(_: DelegateAction) -> Self

    /// InternalActions are actions invoked within the same reducer calls.
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
