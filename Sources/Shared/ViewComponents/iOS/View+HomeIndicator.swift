//
//  View+HomeIndicator.swift
//
//
//  Created by ErrorErrorError on 6/27/23.
//
//

#if os(iOS)
import SwiftUI

public struct HomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {
    public static var defaultValue = false

    public static func reduce(
        value: inout Bool,
        nextValue: () -> Bool
    ) {
        value = nextValue()
    }
}

public extension View {
    func prefersHomeIndicatorAutoHidden(_ value: Bool) -> some View {
        preference(key: HomeIndicatorAutoHiddenPreferenceKey.self, value: value)
    }
}
#endif
