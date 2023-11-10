//
//  ModuleClient.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

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
    }
}

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
