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
import UIKit

public extension View {
    func sheetPresentation(
        isPresenting: Binding<Bool>,
        presentationStyle: UIModalPresentationStyle = .automatic,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        prefersGrabberVisible: Bool = true,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        background(
            SheetPresentation(
                isPresented: isPresenting,
                presentationStyle: presentationStyle,
                detents: detents,
                prefersGrabberVisible: prefersGrabberVisible,
                content: content
            )
        )
    }

    func sheetPresentation(
        item: Binding<(some Any)?>,
        presentationStyle: UIModalPresentationStyle = .automatic,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        prefersGrabberVisible: Bool = true,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheetPresentation(
            isPresenting: item.isPresent(),
            presentationStyle: presentationStyle,
            detents: detents,
            prefersGrabberVisible: prefersGrabberVisible,
            content: content
        )
    }

    func sheetPresentation<State: Equatable, Action>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        presentationStyle: UIModalPresentationStyle = .automatic,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        prefersGrabberVisible: Bool = true,
        @ViewBuilder content: @escaping (Store<State, Action>) -> some View
    ) -> some View {
        presentation(store: store) { `self`, $item, destination in
            self.sheetPresentation(
                item: $item,
                presentationStyle: presentationStyle,
                detents: detents,
                prefersGrabberVisible: prefersGrabberVisible
            ) {
                destination(content)
            }
        }
    }

    func sheetPresentation<State: Equatable, Action, DestinationState, DestinationAction>(
        store: Store<PresentationState<State>, PresentationAction<Action>>,
        state toDestinationState: @escaping (State) -> DestinationState?,
        action fromDestinationAction: @escaping (DestinationAction) -> Action,
        presentationStyle: UIModalPresentationStyle = .automatic,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        prefersGrabberVisible: Bool = true,
        @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
    ) -> some View {
        presentation(
            store: store,
            state: toDestinationState,
            action: fromDestinationAction
        ) { `self`, $item, destination in
            self.sheetPresentation(
                item: $item,
                presentationStyle: presentationStyle,
                detents: detents,
                prefersGrabberVisible: prefersGrabberVisible
            ) {
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
