//
//  PlatformViewRepresentable.swift
//
//
//  Created by ErrorErrorError on 10/12/22.
//

import SwiftUI

#if os(iOS) || os(tvOS)
public typealias PlatformView = UIView
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformViewController = UIViewController
public typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
#elseif os(macOS)
public typealias PlatformView = NSView
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformViewController = NSViewController
public typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
#endif

// MARK: - PlatformAgnosticViewRepresentable

/// Implementers get automatic `UIViewRepresentable` conformance on iOS
/// and `NSViewRepresentable` conformance on macOS.
public protocol PlatformAgnosticViewRepresentable: PlatformViewRepresentable {
    associatedtype PlatformViewType

    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ platformView: PlatformViewType, context: Context)
}

extension PlatformAgnosticViewRepresentable {
    static func dismantlePlatformView(_: PlatformViewType, coordinator _: Coordinator) {}
}

// MARK: - PlatformAgnosticViewControllerRepresentable

public protocol PlatformAgnosticViewControllerRepresentable: PlatformViewControllerRepresentable {
    associatedtype PlatformViewControllerType

    func makePlatformViewController(context: Context) -> PlatformViewControllerType
    func updatePlatformViewController(_ platformViewController: PlatformViewControllerType, context: Context)
    static func dismantlePlatformViewController(_ platformViewController: PlatformViewControllerType, coordinator: Coordinator)
}

public extension PlatformAgnosticViewControllerRepresentable {
    static func dismantlePlatformViewController(_: PlatformViewControllerType, coordinator _: Coordinator) {}
}

#if os(iOS) || os(tvOS)
public extension PlatformAgnosticViewRepresentable where UIViewType == PlatformViewType {
    func makeUIView(context: Context) -> UIViewType {
        makePlatformView(context: context)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        dismantlePlatformView(uiView, coordinator: coordinator)
    }
}

public extension PlatformAgnosticViewControllerRepresentable where UIViewControllerType == PlatformViewControllerType {
    func makeUIViewController(context: Context) -> UIViewControllerType {
        makePlatformViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        updatePlatformViewController(uiViewController, context: context)
    }

    static func dismantleUIViewController(_ uiViewController: UIViewControllerType, coordinator: Coordinator) {
        dismantlePlatformViewController(uiViewController, coordinator: coordinator)
    }
}

#elseif os(macOS)
public extension PlatformAgnosticViewRepresentable where NSViewType == PlatformViewType {
    func makeNSView(context: Context) -> NSViewType {
        makePlatformView(context: context)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        dismantlePlatformView(nsView, coordinator: coordinator)
    }
}

public extension PlatformAgnosticViewControllerRepresentable where NSViewControllerType == PlatformViewControllerType {
    func makeNSViewController(context: Context) -> NSViewControllerType {
        makePlatformViewController(context: context)
    }

    func updateNSViewController(_ uiViewController: NSViewControllerType, context: Context) {
        updatePlatformViewController(uiViewController, context: context)
    }

    static func dismantleNSViewController(_ uiViewController: NSViewControllerType, coordinator: Coordinator) {
        dismantlePlatformViewController(uiViewController, coordinator: coordinator)
    }
}
#endif
