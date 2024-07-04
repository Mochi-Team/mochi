//
//  Library.swift
//
//
//  Created by MochiTeam on 09.04.2024.
//

import Foundation

struct Library: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        FileClient()
        ViewComponents()
        ComposableArchitecture()
        OfflineManagerClient()
        Styling()
        PlaylistDetails()
        DownloadQueue()
        NukeUI()
        SharedModels()
    }
}
