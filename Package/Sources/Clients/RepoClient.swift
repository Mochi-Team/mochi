//
//  RepoClient.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

struct RepoClient: Client {
    var dependencies: any Dependencies {
        DatabaseClient()
        SharedModels()
        TOMLDecoder()
        Tagged()
        ComposableArchitecture()
    }
}
