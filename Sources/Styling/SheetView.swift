//
//  SheetView.swift
//  
//
//  Created by ErrorErrorError on 5/31/23.
//  
//

import ComposableArchitecture
import Foundation
import SwiftUI

extension View {
    @MainActor
    func sheetPresentation(
        isPresenting: Binding<Bool>,
        content: @escaping () -> some View
    ) -> some View {
        self.background(
            SheetPresentation(
                isPresented: isPresenting,
                content: content
            )
        )
    }

    @MainActor
    public func sheetPresentation<State: Equatable, Action>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        @ViewBuilder content: @escaping (Store<State, Action>) -> some View
    ) -> some View {
        self.modifier(
            SheetViewModifier(
                store: store,
                state: { $0 },
                action: { $0 },
                content: content
            )
        )
    }

    @MainActor
    public func sheetView<State: Equatable, Action, DestinationState, DestinationAction>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
    ) -> some View {
        self.modifier(
            SheetViewModifier(
                store: store,
                state: toDestinationState,
                action: fromDestinationAction,
                content: content
            )
        )
    }
}

@MainActor
private struct SheetViewModifier<
    State: Equatable,
    Action,
    DestinationState,
    DestinationAction,
    SheetContent: View
>: ViewModifier {
    let store: Store<PresentationState<State>, PresentationAction<Action>>
    @ObservedObject
    var viewStore: ViewStore<PresentationState<State>, PresentationAction<Action>>
    let toDestinationState: (State) -> DestinationState?
    let fromDestinationAction: (DestinationAction) -> Action
    let sheetContent: (Store<DestinationState, DestinationAction>) -> SheetContent

    @MainActor
    init(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        content sheetContent: @escaping (Store<DestinationState, DestinationAction>) -> SheetContent
    ) {
        self.store = store
        self.viewStore = ViewStore(store) { $0 }
        self.toDestinationState = toDestinationState
        self.fromDestinationAction = fromDestinationAction
        self.sheetContent = sheetContent
    }

    @MainActor
    func body(content: Content) -> some View {
        content.sheetPresentation(
            isPresenting: .init(
                get: { viewStore.wrappedValue.flatMap(toDestinationState) != nil },
                set: { newValue in
                    if viewStore.wrappedValue != nil && !newValue {
                        viewStore.send(.dismiss)
                    }
                }
            )
        ) {
            IfLetStore(
                store.scope(
                    state: { $0.wrappedValue.flatMap(self.toDestinationState) },
                    action: { .presented(self.fromDestinationAction($0)) }
                ),
                then: sheetContent
            )
        }
    }
}

struct SheetView_Previews: PreviewProvider {
    static var previews: some View {
        SheetPresentation(isPresented: .constant(true)) {
            Color.red
        }
    }
}
