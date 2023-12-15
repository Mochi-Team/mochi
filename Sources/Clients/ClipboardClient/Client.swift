//
//  Client.swift
//
//
//  Created ErrorErrorError on 12/15/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - ClipboardClient

public struct ClipboardClient: Sendable {
  public var copyValue: @Sendable (String) -> Void
}

// MARK: TestDependencyKey

extension ClipboardClient: TestDependencyKey {
  public static let testValue = Self(
    copyValue: unimplemented(".copyValue")
  )
}

extension DependencyValues {
  public var clipboardClient: ClipboardClient {
    get { self[ClipboardClient.self] }
    set { self[ClipboardClient.self] = newValue }
  }
}
