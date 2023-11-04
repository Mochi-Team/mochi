//
//  Binding+Env.swift
//
//
//  Created by ErrorErrorError on 7/25/23.
//
//

import Foundation
import WasmInterpreter

// MARK: Env Imports

extension ModuleClient.WAInstance {
    func envImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "env") {
            WasmInstance.Function("print") { (string_ptr: Int32, string_len: Int32) in
                hostBindings.env_print(string_ptr: string_ptr, string_len: string_len)
            }

            WasmInstance.Function("abort") { (msg: Int32, file_name: Int32, line: Int32, column: Int32) in
                hostBindings.env_abort(
                    msg: msg,
                    file_name: file_name,
                    line: line,
                    column: column
                )
            }
        }
    }
}
