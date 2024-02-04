//
//  Index.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

import Foundation

let package = Package {
    // Clients
    ModuleClient()

    ModuleLists()
    PlaylistDetails()
    Discover()
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
