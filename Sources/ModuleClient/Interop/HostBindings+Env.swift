//
//  HostBindings+Env.swift
//
//
//  Created by ErrorErrorError on 7/28/23.
//
//

import Foundation

extension HostBindings {
    func env_print(
        string_ptr: Int32,
        string_len: Int32
    ) {
        let string = try? memory.string(byteOffset: .init(string_ptr), length: .init(string_len))
        Swift.print(string ?? "")
    }
}
