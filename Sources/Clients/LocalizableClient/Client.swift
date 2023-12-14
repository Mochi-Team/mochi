//
//  Client.swift
//
//
//  Created by ErrorErrorError on 12/1/23.
//
//

import Dependencies
import Foundation

// MARK: - LocalizableClient

public struct LocalizableClient {
  public var localize: (String) -> String
}

// MARK: DependencyKey

extension LocalizableClient: DependencyKey {
  public static let liveValue: LocalizableClient = .init(
    localize: { String(localized: .init($0), bundle: .module) }
  )

  public static let previewValue: LocalizableClient = .init(localize: { $0 })

  public static let testValue: LocalizableClient = .init(localize: unimplemented(".localize"))
}

extension DependencyValues {
  public var localizableClient: LocalizableClient {
    get { self[LocalizableClient.self] }
    set { self[LocalizableClient.self] = newValue }
  }
}
