//
//  Client.swift
//  
//
//  Created by ErrorErrorError on 12/1/23.
//  
//

import Dependencies
import Foundation

public struct LocalizableClient {
    public var localize: (String) -> String
}

extension LocalizableClient: DependencyKey {
    public static let liveValue: LocalizableClient = .init(
        localize: { String(localized: .init($0), bundle: .module) }
    )
}

extension DependencyValues {
    public var localizableClient: LocalizableClient {
        get { self[LocalizableClient.self] }
        set { self[LocalizableClient.self] = newValue }
    }
}
