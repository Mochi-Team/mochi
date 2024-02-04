//
// TestTarget.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

// MARK: - TestTarget

protocol TestTarget: Target {}

extension TestTarget {
    var targetType: TargetType {
        .test
    }
}
