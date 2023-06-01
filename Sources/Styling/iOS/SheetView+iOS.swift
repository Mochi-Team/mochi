//
//  SheetView+iOS.swift
//
//
//  Created by ErrorErrorError on 4/20/23.
//
//

#if canImport(UIKit)
import ComposableArchitecture
import Foundation
import SwiftUI
import UIKit
import ViewComponents

struct SheetPresentation<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    @Binding
    private var isPresented: Bool

    @MainActor
    init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            if uiViewController.presentedViewController == nil {
                let sheetViewController = CustomHostingController(innerView: content())
                sheetViewController.modalPresentationStyle = .custom
                sheetViewController.transitioningDelegate = context.coordinator
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

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate, UIViewControllerTransitioningDelegate, SheetTransitioningDelegate {
        let parent: SheetPresentation
        let transition = SheetTransition()

        internal init(parent: SheetPresentation) {
            self.parent = parent
        }

        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            let controller = SheetPresentationController(presentedViewController: presented, presenting: presenting)
            controller.delegate = self
            return controller
        }

        func animationController(
            forPresented presented: UIViewController,
            presenting: UIViewController,
            source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            transition.isPresented = true
            transition.wantsInteractiveStart = false
            return transition
        }

        func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            transition.isPresented = false
            return transition
        }

        func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            transition.isPresented = false
            return transition
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            if parent.isPresented {
                parent.isPresented = false
            }
        }
    }
}

@MainActor
private final class CustomHostingController<Content: View>: UIHostingController<Content> {
    @MainActor
    init<Inner: View>(innerView: Inner) where Content == BoxedView<Inner> {
        let boxed = BoxedView(content: innerView)
        super.init(rootView: boxed)

        boxed.callback.reference = { @MainActor [weak self] sizeInset in
            self?.preferredContentSize = sizeInset.size
        }
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct BoxedView<Content: View>: View {
    let content: Content
    let callback = BoxedCallback<CGRect>()

    var body: some View {
        content
            .background(
                GeometryReader { geometryProxy in
                    Color.clear
                        .onAppear {
                            callback(geometryProxy.frame(in: .local))
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                            callback(geometryProxy.frame(in: .local))
                        }
                        .onChange(of: geometryProxy.frame(in: .local)) { newValue in
                            callback(newValue)
                        }
                }
            )
    }

    final class BoxedCallback<P> {
        var reference: ((P) -> Void)?

        func callAsFunction(_ value: P) {
            reference?(value)
        }
    }
}

/// An object that manages the presentation of a controller with a bottom sheet appearance.
final class SheetPresentationController: UIPresentationController {
    // MARK: - Constants

    /// The corner radius of the sheet.
    private let cornerRadius: CGFloat = 24

    /// The percentage to trigger the dismiss transition.
    private let dismissThreshold: CGFloat = 0.3

    // MARK: - Computed Properties

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView, let presentedView else {
            return super.frameOfPresentedViewInContainerView
        }

        let fittingSize = CGSize(width: containerView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let presentedViewHeight = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height

        /// The maximum height allowed for the sheet. We allow the sheet to reach the top safe area inset.
        let maximumHeight = containerView.frame.height - containerView.safeAreaInsets.top - containerView.safeAreaInsets.bottom

        /// The target height of the presented view.
        /// If the size of the of the presented view could not be computed, meaning its equal to zero, we default to the maximum height.
        let targetHeight = presentedViewHeight == .zero ? maximumHeight : presentedViewHeight

        // Adjust the height of the view by adding the bottom safe area inset.
        let adjustedHeight = min(targetHeight, maximumHeight)

        let targetSize = CGSize(width: containerView.frame.width, height: adjustedHeight)
        let targetOrigin = CGPoint(x: .zero, y: containerView.frame.maxY - targetSize.height)

        return CGRect(origin: targetOrigin, size: targetSize)
    }

    /// The `UIScrollView` embedded in the `presentedView`.
    /// When available, the drag of the scroll view will be used to drive the interactive dismiss transition.
    private var presentedScrollView: UIScrollView? {
        guard let presentedView else {
            return nil
        }

        if let scrollView = presentedView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            return scrollView
        }

        return nil
    }

    /// The object that is managing the presentation and transition.
    private var transitioningDelegate: SheetTransitioningDelegate? {
        presentedViewController.transitioningDelegate as? SheetTransitioningDelegate
    }

    // MARK: - UI Elements

    private lazy var visualEffect: UIBlurEffect = {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            return UIBlurEffect(style: .regular)
        }
    }()

    /// The view displayed behind the presented controller.
    private lazy var backgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedBackgroundView)))
        return view
    }()

    /// The view displaying a handle on the presented view.
    private let handleView: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemFill
        } else {
            view.backgroundColor = .lightGray
        }
        view.frame.size = CGSize(width: 40, height: 4)
        return view
    }()

    /// The pan gesture used to drag and interactively dismiss the sheet.
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(pannedPresentedView))

    // MARK: - Methods

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        containerView?.addSubview(backgroundView)

        presentedView?.addSubview(handleView)

        presentedViewController.transitionCoordinator?.animate { [weak self] _ in
            guard let self else {
                return
            }

            self.presentedView?.layer.cornerRadius = self.cornerRadius
            self.backgroundView.effect = self.visualEffect
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        layoutAccessoryViews()

        guard let presentedView else {
            return
        }

        setupPresentedViewInteraction()

        presentedView.layer.cornerCurve = .continuous
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        presentedViewController.additionalSafeAreaInsets.top = handleView.frame.maxY
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        presentedViewController.transitionCoordinator?.animate { [weak self] _ in
            guard let self else {
                return
            }

            self.presentedView?.layer.cornerRadius = .zero
            self.backgroundView.effect = nil
        }
    }

    // MARK: - Private Helpers

    /// Lays out the accessory views of the presentation.
    private func layoutAccessoryViews() {
        guard let containerView else {
            return
        }

        backgroundView.frame = containerView.bounds

        guard let presentedView else {
            return
        }

        handleView.frame.origin.y = 8
        handleView.center.x = presentedView.center.x

        handleView.layer.cornerRadius = handleView.frame.height / 2
    }

    /// Sets up the interaction on the `presentedView`.
    ///
    /// If the view embeds a `UIScrollView` we will ask the presented view to lay out its contents, then ask for the scroll view's content size.
    /// If the content size is bigger than the frame of the scroll view, then we use the drag of the scroll as driver for the dismiss interaction.
    /// Otherwise we just add the pan gesture recognizer to the presented view.
    private func setupPresentedViewInteraction() {
        guard let presentedView else {
            return
        }

        guard let presentedScrollView else {
            presentedView.addGestureRecognizer(panGesture)
            return
        }

        presentedView.layoutIfNeeded()

        if presentedScrollView.contentSize.height > presentedScrollView.frame.height {
            presentedScrollView.delegate = self
        } else {
            presentedView.addGestureRecognizer(panGesture)
        }
    }

    /// Triggers the dismiss transition in an interactive manner.
    /// - Parameter isInteractive: Whether the transition should be started interactively by the user.
    private func dismiss(interactively isInteractive: Bool) {
        transitioningDelegate?.transition.wantsInteractiveStart = isInteractive
        self.delegate?.presentationControllerWillDismiss?(self)
        presentedViewController.dismiss(animated: true) { [weak self] in
            guard let `self` = self else {
                return
            }

            if !isInteractive || presentedViewController.presentingViewController == nil {
                self.delegate?.presentationControllerDidDismiss?(self)
            } else {
                self.delegate?.presentationControllerDidAttemptToDismiss?(self)
            }
        }
    }

    /// Updates the progress of the dismiss transition.
    /// - Parameter translation: The translation of the presented view used to calculate the progress.
    private func updateTransitionProgress(for translation: CGPoint) {
        guard let transitioningDelegate else {
            return
        }

        guard let presentedView else {
            return
        }

        let adjustedHeight = presentedView.frame.height - translation.y
        let progress = 1 - (adjustedHeight / presentedView.frame.height)
        transitioningDelegate.transition.update(progress)
    }

    /// Handles the ended interaction, either a drag or scroll, on the presented view.
    private func handleEndedInteraction() {
        guard let transitioningDelegate else {
            return
        }

        if transitioningDelegate.transition.dismissFractionComplete > dismissThreshold {
            transitioningDelegate.transition.finish()
        } else {
            transitioningDelegate.transition.cancel()
        }
    }

    @objc
    private func tappedBackgroundView() {
        dismiss(interactively: false)
    }

    @objc
    private func pannedPresentedView(_ recognizer: UIPanGestureRecognizer) {
        guard let presentedView, let containerView else {
            return
        }

        switch recognizer.state {
        case .began:
            dismiss(interactively: true)

        case .changed:
            guard presentedView.frame.maxY >= containerView.frame.maxY else {
                return
            }

            let translation = recognizer.translation(in: presentedView)
            updateTransitionProgress(for: translation)

        case .ended, .cancelled, .failed:
            handleEndedInteraction()

        case .possible:
            break

        @unknown default:
            break
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        // FIXME: Fix orientation size not changing view position
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

extension SheetPresentationController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y <= .zero else {
            return
        }

        dismiss(interactively: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let presentedView else {
            return
        }

        if scrollView.contentOffset.y < .zero {
            let originalOffset = CGPoint(x: scrollView.contentOffset.x, y: -scrollView.safeAreaInsets.top)
            scrollView.setContentOffset(originalOffset, animated: false)
        }

        let translation = scrollView.panGestureRecognizer.translation(in: presentedView)
        updateTransitionProgress(for: translation)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handleEndedInteraction()
    }
}

/// An object that manages the transition animations for a `SheetPresentationController`.
final class SheetTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
    // MARK: - Stored Properties

    /// Whether the transition is used for a presentation. `false` if the transition is for the dismissal.
    var isPresented = true

    /// The interactive animator used for the dismiss transition.
    private var dismissAnimator: UIViewPropertyAnimator?

    /// The animator used for the presentation animation.
    private var presentationAnimator: UIViewPropertyAnimator?

    /// The duration of the transition animation.
    private let animationDuration: TimeInterval = 0.75

    // MARK: - Computed Properties

    /// The progress of the dismiss animation.
    var dismissFractionComplete: CGFloat {
        dismissAnimator?.fractionComplete ?? .zero
    }

    // MARK: - Functions

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        animationDuration
    }

    // This will get called when the transition is not interactive (i.e: presenting or dismissing the controller through the methods).
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    // This will get called when the transition is interactive.
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if isPresented {
            return presentationAnimator ?? presentationInterruptibleAnimator(using: transitionContext)
        } else {
            return dismissAnimator ?? dismissInterruptibleAnimator(using: transitionContext)
        }
    }

    private func presentationInterruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        guard let toViewController = transitionContext.viewController(forKey: .to), let toView = transitionContext.view(forKey: .to) else {
            return UIViewPropertyAnimator()
        }

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 0.9)
        presentationAnimator = animator

        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.frame.origin.y = transitionContext.containerView.frame.maxY

        transitionContext.containerView.addSubview(toView)

        animator.addAnimations {
            toView.frame = transitionContext.finalFrame(for: toViewController)
        }

        animator.addCompletion { position in
            if case .end = position {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }

            transitionContext.completeTransition(false)
        }

        animator.addCompletion { [weak self] _ in
            self?.presentationAnimator = nil
        }

        return animator
    }

    private func dismissInterruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        guard let fromView = transitionContext.view(forKey: .from) else {
            return UIViewPropertyAnimator()
        }

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 0.9)
        dismissAnimator = animator

        animator.addAnimations {
            fromView.frame.origin.y = fromView.frame.maxY
        }

        animator.addCompletion { position in
            if case .end = position {
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }

            transitionContext.completeTransition(false)
        }

        animator.addCompletion { [weak self] _ in
            self?.dismissAnimator = nil
        }

        return animator
    }
}

protocol SheetTransitioningDelegate: AnyObject {
    var transition: SheetTransition { get }
}
#endif
