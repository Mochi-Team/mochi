//
//  Popups.swift
//
//
//  Created by ErrorErrorError on 4/20/23.
//
//

import ComposableArchitecture
import Foundation
import SwiftUI
import ViewComponents

// MARK: - PopupView

public struct PopupView<C: View>: View {
    let content: () -> C
    let dismiss: () -> Void

    @GestureState
    private var gestureTranslation: CGFloat = 0
    @Binding
    private var isPresenting: Bool

    public init(
        isPresenting: Binding<Bool>,
        dismiss: @escaping () -> Void = {},
        content: @escaping () -> C
    ) {
        self._isPresenting = isPresenting
        self.dismiss = dismiss
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()

            if isPresenting {
                content()
                    .background(
                        Color.secondarySystemBackground
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .updating($gestureTranslation) { value, state, _ in
                                        state = value.translation.height > 0 ?
                                            value.translation.height : -log10(abs(value.translation.height))
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 0 || value.predictedEndTranslation.height > 0 {
                                            isPresenting = false
                                        }
                                    }
                            )
                    )
                    .cornerRadius(12)
                    .offset(y: gestureTranslation)
                    .transition(.opacity)
            }

            Spacer()
        }
        .animation(
            .spring(response: 0.34, dampingFraction: 1, blendDuration: 0.4),
            value: isPresenting
        )
        .animation(
            .interactiveSpring(),
            value: gestureTranslation == 0
        )
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black
                .opacity(isPresenting ? 0.3 : 0.0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: isPresenting)
                .onTapGesture {
                    isPresenting = false
                }
        )
    }
}

public extension View {
    func popupView(
        isPresenting: Binding<Bool>,
        content: @escaping () -> some View
    ) -> some View {
        overlay(
            PopupView(
                isPresenting: isPresenting,
                content: content
            )
        )
    }

    func popupView<State: Equatable, Action>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        @ViewBuilder content: @escaping (Store<State, Action>) -> some View
    ) -> some View {
        modifier(
            PopupViewModifier(
                store: store,
                state: { $0 },
                action: { $0 },
                content: content
            )
        )
    }

    func popupView<State: Equatable, Action, DestinationState, DestinationAction>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
    ) -> some View {
        modifier(
            PopupViewModifier(
                store: store,
                state: toDestinationState,
                action: fromDestinationAction,
                content: content
            )
        )
    }
}

// MARK: - PopupViewModifier

private struct PopupViewModifier<
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

    func body(content: Content) -> some View {
        content.popupView(
            isPresenting: .init(
                get: { viewStore.wrappedValue.flatMap(toDestinationState) != nil },
                set: { newValue in
                    if viewStore.wrappedValue != nil, !newValue {
                        viewStore.send(.dismiss)
                    }
                }
            )
        ) {
            IfLetStore(
                store.scope(
                    state: { $0.wrappedValue.flatMap(toDestinationState) },
                    action: { .presented(fromDestinationAction($0)) }
                ),
                then: sheetContent
            )
        }
    }
}

// MARK: - PopupView_Previews

#Preview {
    PopupView(isPresenting: .constant(true)) {
        Color.red
    }
}
