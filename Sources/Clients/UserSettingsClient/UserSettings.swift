//
//  UserSettings.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

public struct UserSettings: Sendable, Equatable, Codable {
    public var theme: Theme

    public init(theme: Theme = .default) {
        self.theme = theme
    }
}
