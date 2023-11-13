//
//  Client+.swift
//
//
//  Created by ErrorErrorError on 11/12/23.
//
//

import Foundation

public extension FileClient {
    func createModuleDirectory(_ url: URL) throws {
        try create(
            self.url(.documentDirectory, .userDomainMask, nil, true)
                .reposDir()
                .appendingPathComponent(url.absoluteString)
        )
    }

    func retrieveModuleDirectory(_ url: URL) throws -> URL {
        try self.url(.documentDirectory, .userDomainMask, nil, false)
            .reposDir()
            .appendingPathComponent(url.absoluteString)
    }
}

private extension URL {
    func reposDir() -> URL {
        self.appendingPathComponent("Repos", isDirectory: true)
    }
}
