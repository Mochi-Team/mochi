//
// Array+Depedencies.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension [Dependency]: Dependencies {
    func appending(_ dependencies: any Dependencies) -> [Dependency] {
        self + dependencies
    }
}
