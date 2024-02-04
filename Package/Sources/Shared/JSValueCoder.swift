//
//  JSValueCoder.swift
//
//
//  Created by ErrorErrorError on 11/6/23.
//
//

import Foundation

// MARK: - JSValueCoder

struct JSValueCoder: _Shared {}

// MARK: Testable

extension JSValueCoder: Testable {
    struct Tests: TestTarget {
        var name: String { "JSValueCoderTests" }

        var dependencies: any Dependencies {
            JSValueCoder()
        }
    }
}
