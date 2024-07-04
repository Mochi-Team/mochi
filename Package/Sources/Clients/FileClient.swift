//
//  FileClient.swift
//
//
//  Created by MochiTeam on 10/6/23.
//
//

struct FileClient: _Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
        SharedModels()
    }
}
