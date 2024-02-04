//
//  DatabaseClient.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct DatabaseClient: _Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
        Semver()
        Tagged()
        CoreDB()
    }

    var resources: [Resource] {
        Resource.copy("Resources/MochiSchema.xcdatamodeld")
    }
}
