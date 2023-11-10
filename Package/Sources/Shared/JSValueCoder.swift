//
//  JSValueCoder.swift
//
//
//  Created by ErrorErrorError on 11/6/23.
//  
//

import Foundation

struct JSValueCoder: _Shared {}

extension JSValueCoder: Testable {
    struct Tests: TestTarget {
        var name: String { "JSValueCoderTests" }

        var dependencies: any Dependencies {
            JSValueCoder()
        }
    }
}
