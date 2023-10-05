//
//  File.swift
//
//
//  Created by ErrorErrorError on 6/11/23.
//
//

import ComposableArchitecture
import Foundation

// MARK: - DateComponentsFormatterKey

public struct DateComponentsFormatterKey: DependencyKey {
    public static let liveValue: DateComponentsFormatter = {
        let locked = LockIsolated(DateComponentsFormatter())
        return locked.value
    }()
}

public extension DependencyValues {
    var dateComponentsFormatter: DateComponentsFormatter {
        get { self[DateComponentsFormatterKey.self] }
        set { self[DateComponentsFormatterKey.self] = newValue }
    }
}
