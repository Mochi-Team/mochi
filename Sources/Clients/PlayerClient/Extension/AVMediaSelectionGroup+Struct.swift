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

// Not sure if this brings performance improvements, if any
public struct MediaSelectionGroup: Hashable, Sendable {
    fileprivate let _ref: AVMediaSelectionGroup

    public var allowsEmptySelection: Bool {
        _ref.allowsEmptySelection
    }

    public var options: [MediaSelectionOption] {
        _ref.options.map { .init($0) }
    }

    fileprivate init(_ ref: AVMediaSelectionGroup) {
        self._ref = ref
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
    fileprivate let _ref: AVMediaSelectionOption

    public var mediaType: AVMediaType {
        _ref.mediaType
    }

    public var displayName: String {
        _ref.displayName
    }

    public var isPlayable: Bool {
        _ref.isPlayable
    }

    fileprivate init(_ ref: AVMediaSelectionOption) {
        self._ref = ref
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_ref)
    }

    public static func == (lhs: Self, rhs: Self) {
        lhs._ref.isEqual(rhs._ref)
    }
}
