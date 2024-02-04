//
// Product+Target.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension Product where Self: Target {
    var productTargets: [Target] {
        [self]
    }

    var targetType: TargetType {
        switch productType {
        case .library:
            .regular

        case .executable:
            .executable
        }
    }
}
