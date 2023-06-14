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

public extension Animation {
    static var navStackTransion: Animation { .timingCurve(0.31, 0.47, 0.31, 1, duration: 0.4) }
}

// MARK: - NavStack

public struct NavStack<State: Equatable, Action, Root: View, Destination: View>: View {
    private let store: Store<StackState<State>, StackAction<State, Action>>
    private let root: Root
    private let destination: (Store<State, Action>) -> Destination
    @StateObject
    private var viewStore: ViewStore<StackState<State>, StackAction<State, Action>>

    public init(
        _ store: Store<StackState<State>, StackAction<State, Action>>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
    ) {
        self.store = store
        self.root = root()
        self.destination = destination
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
            root.zIndex(0)

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
                            .element(id: id, action: childAction)
                        }
                    ) { store in
                        destination(store)
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
        @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
    ) where Root == EmptyView {
        self.init(
            store,
            root: EmptyView.init,
            destination: destination
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
