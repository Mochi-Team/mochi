//
//  Index.swift
//
//
//  Created by MochiTeam on 10/4/23.
//
//

import Foundation

let package = Package {
    // Clients
    ModuleClient()

    ModuleLists()
    PlaylistDetails()
    Discover()
    Library()
    DownloadQueue()
    Repos()
    Search()
    Settings()
    VideoPlayer()
    ContentCore()

    MochiApp()
} testTargets: {
    CoreDB.Tests()
    ModuleClient.Tests()
    JSValueCoder.Tests()
}
.supportedPlatforms {
    MochiPlatforms()
}
.defaultLocalization("en")
