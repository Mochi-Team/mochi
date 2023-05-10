//
//  Models.swift
//  
//
//  Created by ErrorErrorError on 4/8/23.
//  
//

import Foundation
import SharedModels
import Tagged

extension RepoClient {
    public struct RepoModulesResult: Equatable {
        public var installed: [Module] = []
        public var network: [Module] = []
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case failedToFindRepo
        case failedToDownloadModule
        case failedToDownloadRepo
        case failedToAddRepo
        case failedToInstallModule
        case failedToLoadPackages
    }
}

extension RepoClient {
    public enum RepoModuleDownloadState: Equatable, Sendable {
        case pending
        case downloading(percent: Double)
        case installing
        case installed
    }
}
