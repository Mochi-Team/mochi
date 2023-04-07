//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture
import Foundation

extension UserDefaultsClient {
    public static var live: Self {
        let userDefaults = UserDefaults.standard

        return .init(
            doubleForKey: { userDefaults.double(forKey: $0) },
            intForKey: { userDefaults.integer(forKey: $0) },
            boolForKey: { userDefaults.bool(forKey: $0) },
            dataForKey: { userDefaults.data(forKey: $0) },
            setDouble: { userDefaults.setValue($0, forKey: $1) },
            setInt: { userDefaults.setValue($0, forUndefinedKey: $1) },
            setBool: { userDefaults.setValue($0, forKey: $1) },
            setData: { userDefaults.setValue($0, forUndefinedKey: $1) },
            remove: { userDefaults.removeObject(forKey: $0) }
        )
    }
}

extension UserDefaults: @unchecked Sendable {}
