//
//  ContentCore.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct ContentCore: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        FoundationHelpers()
        ModuleClient()
        PlaylistHistoryClient()
        OfflineManagerClient()
        LoggerClient()
        Tagged()
        ComposableArchitecture()
        Styling()
    }
}
