//
//  LoggerClient.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct LoggerClient: Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
    }
}
