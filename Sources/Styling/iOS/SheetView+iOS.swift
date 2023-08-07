//
//  SheetView+iOS.swift
//
//
//  Created by ErrorErrorError on 4/20/23.
//
//

#if os(iOS)
import ComposableArchitecture
import Foundation
import SwiftUI
import UIKit
import ViewComponents

struct SheetPresentation<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    @Binding
    private var isPresented: Bool
    private var presentationStyle: UIModalPresentationStyle = .automatic
    private var detents: [UISheetPresentationController.Detent] = [.medium(), .large()]
    private var prefersGrabberVisible = true

    init(
        isPresented: Binding<Bool>,
        presentationStyle: UIModalPresentationStyle = .automatic,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        prefersGrabberVisible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.presentationStyle = presentationStyle
        self.detents = detents
        self.prefersGrabberVisible = prefersGrabberVisible
        self.content = content
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            if uiViewController.presentedViewController == nil {
                let sheetViewController = CustomHostingController(innerView: content)
                sheetViewController.delegate = context.coordinator
                sheetViewController.sheetPresentationController?.delegate = context.coordinator
                sheetViewController.modalPresentationStyle = presentationStyle
                (sheetViewController.presentationController as? UISheetPresentationController)?.detents = detents
                (sheetViewController.presentationController as? UISheetPresentationController)?.prefersGrabberVisible = prefersGrabberVisible
                sheetViewController.presentationController?.delegate = context.coordinator
                uiViewController.present(sheetViewController, animated: true)
            }
        } else {
            uiViewController.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension SheetPresentation {
    func makeCoordinator() -> Coordinator {
        .init(parent: self)
    }

    final class Coordinator: NSObject, UISheetPresentationControllerDelegate, SheetPresentationDelegate {
        let parent: SheetPresentation

        internal init(parent: SheetPresentation) {
            self.parent = parent
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            if parent.isPresented {
                parent.isPresented = false
            }
        }

        func didDismissed() {
            if parent.isPresented {
                parent.isPresented = false
            }
        }
    }
}

private protocol SheetPresentationDelegate: AnyObject {
    func didDismissed()
}

@MainActor
private final class CustomHostingController<Content: View>: UIHostingController<Content> {
    weak var delegate: SheetPresentationDelegate?

    @MainActor
    init<Inner: View>(innerView: @escaping () -> Inner) where Content == BoxedView<Inner> {
        var boxed = BoxedView(content: innerView)
        super.init(rootView: boxed)

        boxed.sizeCallback = { @MainActor [weak self] sizeInset in
            self?.preferredContentSize = sizeInset.size
        }
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDismissed()
    }
}

private struct BoxedView<Content: View>: View {
    let content: () -> Content

    var sizeCallback: ((CGRect) -> Void)? {
        get { _sizeCallback.reference }
        set { _sizeCallback.reference = newValue }
    }

    private let _sizeCallback = Box<CGRect>()

    var body: some View {
        content()
            .background(
                GeometryReader { geometryProxy in
                    Color.clear
                        .onAppear {
                            _sizeCallback(geometryProxy.frame(in: .local))
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                            _sizeCallback(geometryProxy.frame(in: .local))
                        }
                        .onChange(of: geometryProxy.frame(in: .local)) { newValue in
                            _sizeCallback(newValue)
                        }
                }
            )
    }

    final class Box<P> {
        var reference: ((P) -> Void)?

        func callAsFunction(_ value: P) {
            reference?(value)
        }
    }
}
#endif
