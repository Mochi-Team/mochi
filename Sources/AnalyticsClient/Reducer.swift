//
//  Reducer.swift
//  
//
//  Created by ErrorErrorError on 5/19/23.
//  
//

import ComposableArchitecture
import Foundation

extension Reducer {
    public func analytics(
        _ toEvent: @escaping (State, Action) -> AnalyticsClient.Action? = { _, _ in nil }
    ) -> some Reducer {
        AnalyticsReducer<State, Action>(toAnalyticsAction: toEvent)
    }
}

public struct AnalyticsReducer<State, Action>: Reducer {
    @usableFromInline
    let toAnalyticsAction: (State, Action) -> AnalyticsClient.Action?

    @usableFromInline
    @Dependency(\.analyticsClient)
    var analyticsClient

    @inlinable
    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        guard let event = toAnalyticsAction(state, action) else {
            return .none
        }

        return .run { _ in
            analyticsClient.sendAnalytics(event)
        }
    }
}
