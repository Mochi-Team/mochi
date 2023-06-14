//
//  HostModuleInterop+Json.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation

// MARK: - JSON Imports

extension HostModuleInterop {
    func json_parse(buf_ptr: RawPtr, buf_len: Int32) -> PtrRef {
        handleErrorAlloc { alloc in
            let jsonData = try memory.data(
                byteOffset: Int(buf_ptr),
                length: Int(buf_len)
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
