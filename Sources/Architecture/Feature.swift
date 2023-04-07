//
//  File.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import ComposableArchitecture
import Foundation
import SwiftUI

public protocol FeatureState: Equatable, Sendable {}

public protocol SendableAction: Equatable, Sendable {}

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

    /// InternalActions should be invoked in reducer calls only.
    static func `internal`(_: InternalAction) -> Self
}

public protocol FeatureView: View {
    associatedtype Store
    var store: Store { get }

    init(store: Store)
}

public protocol FeatureReducer: Reducer {
    init()
}

public protocol Feature {
    associatedtype State: FeatureState
    associatedtype Action: FeatureAction
    associatedtype View: FeatureView
    associatedtype Reducer: FeatureReducer
}

public typealias FeatureStoreOf<F: Feature> = StoreOf<F.Reducer>
