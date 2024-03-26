//
//  ContentCore.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct ContentCore: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        FoundationHelpers()
        ModuleClient()
        LoggerClient()
        Tagged()
        ComposableArchitecture()
        Styling()
    }
}
