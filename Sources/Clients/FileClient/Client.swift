//
//  Client.swift
//  
//
//  Created by ErrorErrorError on 10/6/23.
//  
//

import ComposableArchitecture
import Foundation

public struct FileClient {
    public let createModuleFolder: @Sendable (String) -> URL
    public let retrieveModuleFolder: @Sendable (URL) -> URL
}

extension FileClient: TestDependencyKey {
    public static var testValue: FileClient = .init(
        createModuleFolder: unimplemented(".createModuleFolder"),
        retrieveModuleFolder: unimplemented(".retrieveModuleFolder")
    )
}

public extension DependencyValues {
    var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}
