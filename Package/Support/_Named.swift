//
// _Named.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

// MARK: - _Named

protocol _Named {
    var name: String { get }
}

extension _Named {
    var name: String {
        "\(Self.self)"
    }
}
