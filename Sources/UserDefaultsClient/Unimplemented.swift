//
//  Mock.swift
//  
//
//  Created ErrorErrorError on 4/6/23.
//  Copyright © 2023. All rights reserved.
//

import ComposableArchitecture

extension UserDefaultsClient {
    public static var unimplemented: Self {
        .init(
            doubleForKey: { _ in 0 },
            intForKey: { _ in 0 },
            boolForKey: { _ in false },
            dataForKey: { _ in nil },
            setDouble: { _, _ in },
            setInt: { _, _ in },
            setBool: { _, _ in },
            setData: { _, _ in },
            remove: { _ in }
        )
    }
}
