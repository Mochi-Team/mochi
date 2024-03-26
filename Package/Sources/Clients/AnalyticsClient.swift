//
//  AnalyticsClient.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

import Foundation

struct AnalyticsClient: _Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
    }
}
