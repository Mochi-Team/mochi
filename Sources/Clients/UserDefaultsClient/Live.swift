//
//  Live.swift
//
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation

// MARK: - UserDefaultsClient + DependencyKey

extension UserDefaultsClient: DependencyKey {
  public static let liveValue = Self(
    doubleForKey: { UserDefaults.standard.double(forKey: $0) },
    intForKey: { UserDefaults.standard.integer(forKey: $0) },
    boolForKey: { UserDefaults.standard.bool(forKey: $0) },
    dataForKey: { UserDefaults.standard.data(forKey: $0) },
    setDouble: { UserDefaults.standard.setValue($0, forKey: $1) },
    setInt: { UserDefaults.standard.setValue($0, forUndefinedKey: $1) },
    setBool: { UserDefaults.standard.setValue($0, forKey: $1) },
    setData: { UserDefaults.standard.setValue($0, forUndefinedKey: $1) },
    remove: { UserDefaults.standard.removeObject(forKey: $0) }
  )
}

// MARK: - UserDefaults + Sendable

extension UserDefaults: @unchecked Sendable {}
