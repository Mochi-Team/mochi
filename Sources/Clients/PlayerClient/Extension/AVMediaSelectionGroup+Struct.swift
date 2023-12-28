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
  public var selected: MediaSelectionOption?
  public var options: [MediaSelectionOption]
  public var defaultOption: MediaSelectionOption?
  public var allowsEmptySelection: Bool

  let _ref: AVMediaSelectionGroup

  public init(
    displayName: String,
    selected: MediaSelectionOption? = nil,
    options: [MediaSelectionOption] = [],
    defaultOption: MediaSelectionOption? = nil,
    allowsEmptySelection: Bool
  ) {
    self.displayName = displayName
    self.selected = selected
    self.options = options
    self.defaultOption = defaultOption
    self.allowsEmptySelection = allowsEmptySelection
    self._ref = .init()
  }

  init(
    name: String,
    selected: MediaSelectionOption? = nil,
    _ ref: AVMediaSelectionGroup
  ) {
    self._ref = ref
    self.displayName = name
    self.selected = selected
    self.options = _ref.options.map { .init($0) }
    self.defaultOption = _ref.defaultOption.flatMap { .init($0) }
    self.allowsEmptySelection = _ref.allowsEmptySelection
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(displayName)
    hasher.combine(selected)
    hasher.combine(options)
    hasher.combine(defaultOption)
    hasher.combine(allowsEmptySelection)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.displayName == rhs.displayName &&
    lhs.selected == rhs.selected &&
    lhs.options == rhs.options &&
    lhs.defaultOption == rhs.defaultOption &&
    lhs.allowsEmptySelection == rhs.allowsEmptySelection
  }
}

// MARK: - MediaSelectionOption

public struct MediaSelectionOption: Hashable, Sendable {
  public var mediaType: AVMediaType
  public var displayName: String
  public var isPlayable: Bool

  let _ref: AVMediaSelectionOption

  init(
    mediaType: AVMediaType,
    displayName: String,
    isPlayable: Bool
  ) {
    self.mediaType = mediaType
    self.displayName = displayName
    self.isPlayable = isPlayable
    self._ref = .init()
  }

  init(_ ref: AVMediaSelectionOption) {
    self._ref = ref
    self.mediaType = _ref.mediaType
    self.displayName = _ref.displayName
    self.isPlayable = _ref.isPlayable
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(mediaType)
    hasher.combine(displayName)
    hasher.combine(isPlayable)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.mediaType == rhs.mediaType &&
    lhs.displayName == rhs.displayName &&
    lhs.isPlayable == rhs.isPlayable
  }
}
