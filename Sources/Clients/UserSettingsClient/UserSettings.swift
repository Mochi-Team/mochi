//
//  UserSettings.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

public struct UserSettings: Sendable, Equatable, Codable {
    public var theme: Theme
    public var appIcon: AppIcon

    public init(
        theme: Theme = .automatic,
        appIcon: AppIcon = .default
    ) {
        self.theme = theme
        self.appIcon = appIcon
    }
}
