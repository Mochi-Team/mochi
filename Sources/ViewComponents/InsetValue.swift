//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

public class InsetableValues: @unchecked Sendable, ObservableObject {
    static var _current = InsetableValues()

    @Published var values = [ObjectIdentifier: CGSize]()

    private init() {}

    public subscript<K: InsetableKey>(key: K.Type) -> CGSize {
        get {
            values[ObjectIdentifier(key)] ?? K.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}

public protocol InsetableKey {
    static var defaultValue: CGSize { get }
}

@propertyWrapper
public struct InsetValue: @unchecked Sendable, DynamicProperty {
    @ObservedObject var values = InsetableValues._current

    private let keyPath: KeyPath<InsetableValues, CGSize>

    public init(_ keyPath: KeyPath<InsetableValues, CGSize>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: CGSize {
        InsetableValues._current[keyPath: keyPath]
    }
}

public extension View {
    @MainActor
    func inset<V: View>(
        for key: WritableKeyPath<InsetableValues, CGSize>,
        alignment: SwiftUI.Alignment = .center,
        _ content: V
    ) -> some View {
        self.overlay(alignment: alignment) {
            content
                .readSize { size in
                    InsetableValues._current[keyPath: key] = size.size
                }
        }
    }

    @MainActor
    func inset<V: View>(
        for key: WritableKeyPath<InsetableValues, CGSize>,
        alignment: SwiftUI.Alignment = .center,
        @ViewBuilder _ content: @escaping () -> V
    ) -> some View {
        self.inset(for: key, alignment: .bottom, content())
    }
}
