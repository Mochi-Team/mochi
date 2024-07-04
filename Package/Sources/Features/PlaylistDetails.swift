//
//  PlaylistDetails.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

import Foundation

struct PlaylistDetails: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        ContentCore()
        LoggerClient()
        ModuleClient()
        RepoClient()
        OfflineManagerClient()
        PlaylistHistoryClient()
        Styling()
        SharedModels()
        ViewComponents()
        ComposableArchitecture()
        NukeUI()
    }
}
