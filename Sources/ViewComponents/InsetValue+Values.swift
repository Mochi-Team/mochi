//
//  InsetValue+Values.swift
//
//
//  Created by ErrorErrorError on 4/19/23.
//
//

import Foundation

// MARK: - InsetTabNavigationKey

public struct InsetTabNavigationKey: InsetableKey {
    public static var defaultValue: CGSize = .zero
}

public extension InsetableValues {
    var bottomNavigation: CGSize {
        get { self[InsetTabNavigationKey.self] }
        set { self[InsetTabNavigationKey.self] = newValue }
    }
}
