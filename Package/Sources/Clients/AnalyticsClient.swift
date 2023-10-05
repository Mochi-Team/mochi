//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/4/23.
//  
//

import Foundation

struct AnalyticsClient: Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
    }
}
