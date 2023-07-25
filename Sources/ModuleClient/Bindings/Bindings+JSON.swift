//
//  HostModuleInterop+Json.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import WasmInterpreter

// MARK: JSON Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func jsonImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "json") {
            WasmInstance.Function("json_parse") { [self] (
                bufPtr: RawPtr,
                bufLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let jsonData = try memory.data(
                        byteOffset: Int(bufPtr),
                        length: Int(bufLen)
                    )

                    guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    if let json = jsonObject as? [String: Any] {
                        return alloc.add(json)
                    } else if let json = jsonObject as? [Any] {
                        return alloc.add(json)
                    } else {
                        throw ModuleClient.Error.castError(
                            got: .init(describing: jsonObject.self),
                            expected: .init(describing: [Any?].self)
                        )
                    }
                }
            }
        }
    }
}
