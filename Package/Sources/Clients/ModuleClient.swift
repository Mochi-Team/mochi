//
//  ModuleClient.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

// MARK: - ModuleClient

struct ModuleClient: _Client {
    var dependencies: any Dependencies {
        DatabaseClient()
        FileClient()
        SharedModels()
        Tagged()
        ComposableArchitecture()
        SwiftSoup()
        Semaphore()
        JSValueCoder()
        LoggerClient()
        Parsing()
    }
}

// MARK: Testable

extension ModuleClient: Testable {
    struct Tests: TestTarget {
        var name: String { "ModuleClientTests" }

        var dependencies: any Dependencies {
            ModuleClient()
        }

        var resources: [Resource] {
            Resource.copy("Resources")
        }
    }
}
