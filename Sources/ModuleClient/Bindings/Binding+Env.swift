//
//  Bindings+Env.swift
//  
//
//  Created by ErrorErrorError on 7/25/23.
//  
//

import Foundation
import WasmInterpreter

// MARK: Env Imports

extension ModuleClient.Instance {
    func envImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "env") {
            WasmInstance.Function("print") { (string_ptr: Int32, string_len: Int32) in
                let string = try? memory.string(byteOffset: .init(string_ptr), length: .init(string_len))
                Swift.print(string ?? "")
            }
        }
    }
}
