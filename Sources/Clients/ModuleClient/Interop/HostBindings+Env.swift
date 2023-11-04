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

    func env_abort(
        msg: Int32,
        file_name: Int32,
        line: Int32,
        column: Int32
    ) {
        let messageLen = try? memory.bytes(
            byteOffset: .init(msg - 4),
            length: 1
        ).first

        let fileLength = (try? memory.bytes(byteOffset: .init(file_name - 4), length: 1).first) ?? 0

        let message = try? memory.string(byteOffset: .init(msg), length: .init(messageLen ?? 0))
        let file = try? memory.string(byteOffset: .init(file_name), length: .init(fileLength))

        Swift.print("[Abort] \(message ?? "") \(file ?? ""):\(line):\(column)")
    }
}
