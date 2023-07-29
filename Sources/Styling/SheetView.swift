//
//  SheetView.swift
//
//
//  Created by ErrorErrorError on 5/31/23.
//
//

@_spi(Presentation)
import ComposableArchitecture
import Foundation
import SwiftUI

public extension View {
    @MainActor
    func sheetPresentation(
        isPresenting: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        background(
            SheetPresentation(
                isPresented: isPresenting,
                content: content
            )
        )
    }

    @MainActor
    func sheetPresentation(
        item: Binding<(some Any)?>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheetPresentation(isPresenting: item.isPresent(), content: content)
    }

    @MainActor
    func sheetPresentation<State: Equatable, Action>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        @ViewBuilder content: @escaping (Store<State, Action>) -> some View
    ) -> some View {
        presentation(store: store) { `self`, $item, destination in
            self.sheetPresentation(item: $item) {
                destination(content)
            }
        }
    }

    @MainActor
    func sheetPresentation<State: Equatable, Action, DestinationState, DestinationAction>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
    ) -> some View {
        presentation(
            store: store,
            state: toDestinationState,
            action: fromDestinationAction
        ) { `self`, $item, destination in
            self.sheetPresentation(item: $item) {
                destination(content)
            }
        }
    }
}

// MARK: - SheetView_Previews

struct SheetView_Previews: PreviewProvider {
    static var previews: some View {
        SheetPresentation(isPresented: .constant(true)) {
            Color.red
        }
    }
}

private extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        .init(
            get: { self.wrappedValue != nil },
            set: { isPresent, transaction in
                if !isPresent {
                    self.transaction(transaction).wrappedValue = nil
                }
            }
        )
    }
}
