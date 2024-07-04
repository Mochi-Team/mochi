//
//  LoggerClient.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct LoggerClient: _Client {
    var dependencies: any Dependencies {
        ComposableArchitecture()
        Logging()
    }
}
