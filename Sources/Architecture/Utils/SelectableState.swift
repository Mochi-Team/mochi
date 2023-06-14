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

@propertyWrapper
public struct SelectableState<Element: Identifiable> {
    var _selected: Element.ID?
    var _wrappedValue: IdentifiedArrayOf<Element>

    public init(
        selected: Element.ID? = nil,
        wrappedValue: IdentifiedArrayOf<Element> = []
    ) {
        self._selected = selected
        self._wrappedValue = wrappedValue
    }

    public var wrappedValue: IdentifiedArrayOf<Element> {
        get { _wrappedValue }
        set { update(newValue) }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }

    public var selected: Element.ID? {
        get { _selected }
        set { _selected = newValue }
    }

    public var element: Element? {
        get { _selected.flatMap { _wrappedValue[id: $0] } }
        set { _selected.flatMap { _wrappedValue[id: $0] = newValue } }
    }

    private mutating func update(_ newValue: IdentifiedArrayOf<Element>) {
        if let _selected {
            self._selected = newValue[id: _selected]?.id
        }

        _wrappedValue = newValue
    }
}

// MARK: - IdentifiedArray + Sendable

extension IdentifiedArray: Sendable where Element: Sendable, ID: Sendable {}

// MARK: - SelectableState + Equatable

extension SelectableState: Equatable where Element: Equatable {}

// MARK: - SelectableState + Hashable

extension SelectableState: Hashable where Element: Hashable {}

// MARK: - SelectableState + Sendable

extension SelectableState: Sendable where Element: Sendable, Element.ID: Sendable {}
