//
//  HostModuleInterop+Http.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import WasmInterpreter

// MARK: HTTP Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func httpImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "http") {
            WasmInstance.Function("create") { [self] (method: Int32) -> Int32 in
                hostBindings.request_create(method: method)
            }

            WasmInstance.Function("send") { [self] (ptr: ReqRef) in
                hostBindings.request_send(ptr: ptr)
            }

            WasmInstance.Function("close") { [self] (ptr: ReqRef) in
                hostBindings.request_close(ptr: ptr)
            }

            WasmInstance.Function("set_url") { [self] (
                ptr: ReqRef,
                urlPtr: Int32,
                urlLen: Int32
            ) in
                hostBindings.request_set_url(
                    ptr: ptr,
                    url_ptr: urlPtr,
                    url_len: urlLen
                )
            }

            WasmInstance.Function("set_header") { [self] (
                ptr: ReqRef,
                keyPtr: Int32,
                keyLen: Int32,
                valuePtr: Int32,
                valueLen: Int32
            ) in
                hostBindings.request_set_header(
                    ptr: ptr,
                    key_ptr: keyPtr,
                    key_len: keyLen,
                    value_ptr: valuePtr,
                    value_len: valueLen
                )
            }

            WasmInstance.Function("set_body") { [self] (
                ptr: Int32,
                dataPtr: Int32,
                dataLen: Int32
            ) in
                hostBindings.request_set_body(
                    ptr: ptr,
                    data_ptr: dataPtr,
                    data_len: dataLen
                )
            }

            WasmInstance.Function("set_method") { [self] (
                ptr: Int32,
                method: Int32
            ) in
                hostBindings.request_set_method(ptr: ptr, method: method)
            }

            WasmInstance.Function("get_method") { [self] (
                ptr: Int32
            ) -> WasmRequest.Method.RawValue in
                hostBindings.request_get_method(ptr: ptr)
            }

            WasmInstance.Function("get_url") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.request_get_url(ptr: ptr)
            }

            WasmInstance.Function("get_header") { [self] (
                ptr: Int32,
                keyPtr: Int32,
                keyLen: Int32
            ) -> Int32 in
                hostBindings.request_get_header(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("get_status_code") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.request_get_status_code(ptr: ptr)
            }

            WasmInstance.Function("get_data_len") { [self] (
                ptr: ReqRef
            ) -> Int32 in
                hostBindings.request_get_data_len(ptr: ptr)
            }

            WasmInstance.Function("get_data") { [self] (
                ptr: Int32,
                arrRef: Int32,
                arrLen: Int32
            ) in
                hostBindings.request_get_data(ptr: ptr, arr_ptr: arrRef, arr_len: arrLen)
            }
        }
    }
}
