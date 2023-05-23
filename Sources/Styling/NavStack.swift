//
//  NavStack.swift
//  
//
//  Created by ErrorErrorError on 5/20/23.
//  
//

import ComposableArchitecture
import Foundation
import OrderedCollections
import SwiftUI
import ViewComponents

public protocol DismissableViewAction: Equatable {
    static func dismissed(_ childAction: Self) -> Bool
}

public extension Animation {
    static var navStackTransion: Animation { .timingCurve(0.31, 0.47, 0.31, 1, duration: 0.4) }
}

public struct NavStack<State: Equatable, Action: DismissableViewAction, Initial: View, Content: View>: View {
    private let store: Store<StackState<State>, StackAction<State, Action>>
    private let initial: () -> Initial
    private let content: (Store<State, Action>) -> Content
    @StateObject private var viewStore: ViewStore<StackState<State>, StackAction<State, Action>>

    public init(
        _ store: Store<StackState<State>, StackAction<State, Action>>,
        @ViewBuilder initial: @escaping () -> Initial,
        @ViewBuilder content: @escaping (Store<State, Action>) -> Content
    ) {
        self.store = store
        self.initial = initial
        self.content = content
        self._viewStore = .init(
            wrappedValue: .init(
                store,
                observe: { $0 },
                removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
            )
        )
    }

    public var body: some View {
        ZStack {
            initial()
                .zIndex(0)

            if !viewStore.isEmpty {
                Color.black
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }

            WithViewStore(
                store,
                observe: \.ids,
                removeDuplicates: areOrderedSetsDuplicates
            ) { viewStore in
                ForEach(viewStore.state, id: \.self) { id in
                    IfLetStore(
                        store.scope(state: \.[id: id]) { (childAction: Action) in
                            if Action.dismissed(childAction) {
                                return .popFrom(id: id)
                            } else {
                                return .element(id: id, action: childAction)
                            }
                        }
                    ) { store in
                        content(store)
                            .screenDismissed {
                                viewStore.send(.popFrom(id: id))
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .zIndex(2)
        }
        .animation(.navStackTransion, value: viewStore.ids)
    }
}

public extension NavStack {
    init(
        _ store: Store<StackState<State>, StackAction<State, Action>>,
        @ViewBuilder content: @escaping (Store<State, Action>) -> Content
    ) where Initial == EmptyView {
        self.init(
            store,
            initial: EmptyView.init,
            content: content
        )
    }
}

// From: https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/SwiftUI/ForEachStore.swift#L134
@inlinable
func areOrderedSetsDuplicates<T>(_ lhs: OrderedSet<T>, _ rhs: OrderedSet<T>) -> Bool {
    var lhs = lhs
    var rhs = rhs
    return memcmp(&lhs, &rhs, MemoryLayout<OrderedSet<T>>.size) == 0 || lhs == rhs
}
