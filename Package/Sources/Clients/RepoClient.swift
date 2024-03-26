//
//  RepoClient.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

struct RepoClient: _Client {
    var dependencies: any Dependencies {
        DatabaseClient()
        FileClient()
        Semaphore()
        SharedModels()
        Tagged()
        ComposableArchitecture()
    }
}
