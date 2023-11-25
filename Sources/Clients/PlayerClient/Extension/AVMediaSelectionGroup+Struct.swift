//
//  AVMediaSelectionGroup+Struct.swift
//
//
//  Created by ErrorErrorError on 7/16/23.
//
//

@preconcurrency
import AVKit
import Foundation

// MARK: - MediaSelectionGroup

public struct MediaSelectionGroup: Hashable, Sendable {
    public var displayName: String
    public private(set) var selected: MediaSelectionOption?

    let _ref: AVMediaSelectionGroup

    init(
        name: String,
        selected: MediaSelectionOption? = nil,
        _ ref: AVMediaSelectionGroup
    ) {
        self._ref = ref
        self.displayName = name
        self.selected = selected
    }

    public var allowsEmptySelection: Bool {
        _ref.allowsEmptySelection
    }

    public var options: [MediaSelectionOption] {
        _ref.options.map { .init($0) }
    }

    public var defaultOption: MediaSelectionOption? {
        _ref.defaultOption.flatMap { .init($0) }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_ref)
    }

    public static func == (lhs: Self, rhs: Self) {
        lhs._ref.isEqual(rhs._ref)
    }
}

// MARK: - MediaSelectionOption

public struct MediaSelectionOption: Hashable, Sendable {
    let _ref: AVMediaSelectionOption

    init(_ ref: AVMediaSelectionOption) {
        self._ref = ref
    }

    public var mediaType: AVMediaType {
        _ref.mediaType
    }

    public var displayName: String {
        _ref.displayName
    }

    public var isPlayable: Bool {
        _ref.isPlayable
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_ref)
    }

    public static func == (lhs: Self, rhs: Self) {
        lhs._ref.isEqual(rhs._ref)
    }
}
