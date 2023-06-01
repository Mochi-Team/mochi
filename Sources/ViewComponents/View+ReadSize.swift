//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/21/23.
//  
//

import Foundation
import SwiftUI

public struct SizeInset {
    public let size: CGSize
    public let safeAreaInsets: EdgeInsets

    public var horizontal: CGFloat {
        size.width + safeAreaInsets.leading + safeAreaInsets.trailing
    }

    public var vertical: CGFloat {
        size.height + safeAreaInsets.top + safeAreaInsets.bottom
    }

    public static var zero: Self {
        .init(size: .zero, safeAreaInsets: .init())
    }
}

extension SizeInset: Equatable {}
extension SizeInset: Sendable {}

public extension View {
    @MainActor
    func readSize(_ callback: @escaping (SizeInset) -> Void) -> some View {
        self
            .background(
                GeometryReader { geometryProxy in
                    Color.clear
                        .onAppear {
                            callback(
                                .init(
                                    size: geometryProxy.size,
                                    safeAreaInsets: geometryProxy.safeAreaInsets
                                )
                            )
                        }
                        #if os(iOS)
                        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                            callback(
                                .init(
                                    size: geometryProxy.size,
                                    safeAreaInsets: geometryProxy.safeAreaInsets
                                )
                            )
                        }
                        #endif
                        .onChange(of: geometryProxy.size) { newValue in
                            callback(
                                .init(
                                    size: newValue,
                                    safeAreaInsets: geometryProxy.safeAreaInsets
                                )
                            )
                        }
                }
            )
    }
}
