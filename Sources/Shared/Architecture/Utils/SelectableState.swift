//
//  SelectableState.swift
//
//
//  Created by ErrorErrorError on 5/11/23.
//
//
//

import ComposableArchitecture
import Foundation
import IdentifiedCollections
import SwiftUI

// MARK: - SelectableState

// swiftlint:disable type_name
@propertyWrapper
public struct SelectableState<C: IdentifiableAccess> {
    var _selected: C.ID?
    var _wrappedValue: C

    public init(
        selected: C.ID? = nil,
        wrappedValue: C
    ) {
        self._selected = selected
        self._wrappedValue = wrappedValue
    }

//    public init(
//        selected: Element.ID? = nil,
//        wrappedValue: IdentifiedArrayOf<Element> = []
//    ) where Element: Identifiable, ID == Element.ID {
//        self._selected = selected
//        self._wrappedValue = wrappedValue
//    }

    public var wrappedValue: C {
        get { _wrappedValue }
        set { update(newValue) }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    public var selected: C.ID? {
        get { _selected }
        set { _selected = newValue }
    }

    public var element: C.Value? {
        get { _selected.flatMap { _wrappedValue[id: $0] } }
        set { _selected.flatMap { _wrappedValue[id: $0] = newValue } }
    }

    private mutating func update(_ newValue: C) {
        // TODO: Figure out if selected should be updated
//        if let _selected {
//            self._selected = newValue[id: _selected] == nil ? nil : _selected
//        }
        _wrappedValue = newValue
    }
}

// MARK: - IdentifiableAccess

public protocol IdentifiableAccess {
    associatedtype ID: Hashable
    associatedtype Value
    subscript(id _: ID) -> Value? { get set }
}

// MARK: - Dictionary + IdentifiableAccess

extension Dictionary: IdentifiableAccess {
    public typealias ID = Key
    public typealias Value = Value

    public subscript(id id: Key) -> Value? {
        get { self[id] }
        set { self[id] = newValue }
    }
}

// MARK: - IdentifiedArray + IdentifiableAccess

extension IdentifiedArray: IdentifiableAccess {}

// MARK: - Identified + Sendable

extension Identified: @unchecked Sendable where Value: Sendable, ID: Sendable {}

// MARK: - IdentifiedArray + Sendable

extension IdentifiedArray: Sendable where Element: Sendable, ID: Sendable {}

// MARK: - SelectableState + Equatable

extension SelectableState: Equatable where C: Equatable, C.Value: Equatable, C.ID: Equatable {}

// MARK: - SelectableState + Hashable

extension SelectableState: Hashable where C: Hashable, C.Value: Hashable, C.ID: Hashable {}

// MARK: - SelectableState + Sendable

extension SelectableState: Sendable where C: Sendable, C.Value: Sendable, C.ID: Sendable {}
