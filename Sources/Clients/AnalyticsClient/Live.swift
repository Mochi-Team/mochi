//
//  Live.swift
//
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation

// TODO: Implement analytics to better understand how people use this app
extension AnalyticsClient: DependencyKey {
    public static let liveValue = Self { _ in }
}
