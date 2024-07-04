//
//  Settings.swift
//
//
//  Created by MochiTeam on 10/5/23.
//
//

struct Settings: _Feature {
    var dependencies: any Dependencies {
        Architecture()
        BuildClient()
        FluidGradient()
        ModuleClient()
        ModuleLists()
        SharedModels()
        Styling()
        ViewComponents()
        PlaylistHistoryClient()
        UserSettingsClient()
        ComposableArchitecture()
        NukeUI()
    }
}
