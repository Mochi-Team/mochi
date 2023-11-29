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
import SwiftUIBackports

#if canImport(UIKit)
import UIKit

public extension View {
    func sheet(
        isPresenting: Binding<Bool>,
        detents: [UISheetPresentationController.Detent],
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheet(isPresented: isPresenting, onDismiss: nil) {
            if #available(iOS 16.0, *) {
                content()
                    .presentationDetents(
                        .init(
                            detents.compactMap { detent in
                                if detent == .medium() {
                                    .medium
                                } else if detent == .large() {
                                    .large
                                } else {
                                    nil
                                }
                            }
                        )
                    )
            } else {
                content()
                    .backport
                    .presentationDetents(
                        .init(
                            detents.compactMap { detent in
                                if detent == .medium() {
                                    .medium
                                } else if detent == .large() {
                                    .large
                                } else {
                                    nil
                                }
                            }
                        )
                    )
            }
        }
    }

    func sheet(
        item: Binding<(some Any)?>,
        detents: [UISheetPresentationController.Detent],
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheet(
            isPresenting: item.isPresent(),
            detents: detents,
            content: content
        )
    }

    func sheet<State: Equatable, Action>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        detents: [UISheetPresentationController.Detent],
        @ViewBuilder content: @escaping (Store<State, Action>) -> some View
    ) -> some View {
        presentation(store: store) { `self`, $item, destination in
            self.sheet(
                item: $item,
                detents: detents
            ) {
                destination(content)
            }
        }
    }

    func sheet<State: Equatable, Action, DestinationState, DestinationAction>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        detents: [UISheetPresentationController.Detent],
        @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
    ) -> some View {
        presentation(
            store: store,
            state: toDestinationState,
            action: fromDestinationAction
        ) { `self`, $item, destination in
            self.sheet(
                item: $item,
                detents: detents
            ) {
                destination(content)
            }
        }
    }
}
#endif

// MARK: - SheetView_Previews

#Preview {
    EmptyView()
}

public extension Binding {
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
