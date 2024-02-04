//
// Array+SupportedPlatforms.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension [SupportedPlatform]: SupportedPlatforms {
    func appending(_ platforms: any SupportedPlatforms) -> Self {
        self + .init(platforms)
    }
}
