//
//  RepoModuleID.swift
//
//
//  Created by ErrorErrorError on 6/2/23.
//
//

@_exported
import DatabaseClient
import Foundation

public struct RepoModuleID: Hashable, Sendable {
    public let repoId: Repo.ID
    public let moduleId: Module.ID

    public init(
        repoId: Repo.ID,
        moduleId: Module.ID
    ) {
        self.repoId = repoId
        self.moduleId = moduleId
    }
}
