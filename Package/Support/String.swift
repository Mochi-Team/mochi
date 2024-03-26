//
// String.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

extension String {
    var packageName: String? {
        split(separator: "/").last?.split(separator: ".").first.map(String.init)
    }
}
