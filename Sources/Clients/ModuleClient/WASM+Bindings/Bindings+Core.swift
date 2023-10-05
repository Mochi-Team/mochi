//
//  Bindings+Core.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SwiftSoup
import WasmInterpreter

// MARK: - Core Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func coreImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "core") {
            WasmInstance.Function("copy") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                hostBindings.core_copy(ptr: ptr)
            }

            WasmInstance.Function("destroy") { [self] (ptr: Int32) in
                hostBindings.core_destroy(ptr: ptr)
            }

            WasmInstance.Function("create_array") { [self] () -> Int32 in
                hostBindings.core_create_array()
            }

            WasmInstance.Function("create_obj") { [self] in
                hostBindings.core_create_obj()
            }

            WasmInstance.Function("create_string") { [self] (
                bufPtr: RawPtr,
                bufLen: Int32
            ) -> Int32 in
                hostBindings.core_create_string(buf_ptr: bufPtr, buf_len: bufLen)
            }

            WasmInstance.Function("create_bool") { [self] (
                value: Int32
            ) -> Int32 in
                hostBindings.core_create_bool(value: value)
            }

            WasmInstance.Function("create_float") { [self] (
                value: Float64
            ) -> Int32 in
                hostBindings.core_create_float(value: value)
            }

            WasmInstance.Function("create_int") { [self] (
                value: Int64
            ) -> Int32 in
                hostBindings.core_create_int(value: value)
            }

            WasmInstance.Function("create_error") { [self] () -> Int32 in
                hostBindings.core_create_error()
            }

            WasmInstance.Function("ptr_kind") { [self] (
                ptr: PtrRef
            ) -> PtrKind.RawValue in
                hostBindings.core_ptr_kind(ptr: ptr)
            }

            WasmInstance.Function("string_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.core_string_len(ptr: ptr)
            }

            WasmInstance.Function("read_string") { [self] (
                ptr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostBindings.core_read_string(ptr: ptr, buf_ptr: bufPtr, len: bufLen)
            }

            WasmInstance.Function("read_int") { [self] (
                ptr: Int32
            ) -> Int64 in
                hostBindings.core_read_int(ptr: ptr)
            }

            WasmInstance.Function("read_float") { [self] (
                ptr: Int32
            ) -> Float64 in
                hostBindings.core_read_float(ptr: ptr)
            }

            WasmInstance.Function("read_bool") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.core_read_bool(ptr: ptr)
            }

            WasmInstance.Function("obj_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.core_obj_len(ptr: ptr)
            }

            WasmInstance.Function("obj_get") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32
            ) -> Int32 in
                hostBindings.core_obj_get(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("obj_set") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32,
                valuePtr: PtrRef
            ) in
                hostBindings.core_obj_set(ptr: ptr, key_ptr: keyPtr, key_len: keyLen, value_ptr: valuePtr)
            }

            WasmInstance.Function("obj_remove") { [self] (
                ptr: Int32,
                keyPtr: Int32,
                keyLen: Int32
            ) in
                hostBindings.core_obj_remove(ptr: ptr, key_ptr: keyPtr, key_len: keyLen)
            }

            WasmInstance.Function("obj_keys") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                hostBindings.core_obj_keys(ptr: ptr)
            }

            WasmInstance.Function("obj_values") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.core_obj_values(ptr: ptr)
            }

            WasmInstance.Function("array_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostBindings.core_array_len(ptr: ptr)
            }

            WasmInstance.Function("array_get") { [self] (
                ptr: PtrRef,
                idx: Int32
            ) -> Int32 in
                hostBindings.core_array_get(ptr: ptr, idx: idx)
            }

            WasmInstance.Function("array_set") { [self] (
                ptr: Int32,
                idx: Int32,
                valuePtr: Int32
            ) in
                hostBindings.core_array_set(ptr: ptr, idx: idx, value_ptr: valuePtr)
            }

            WasmInstance.Function("array_append") { [self] (
                ptr: Int32,
                valuePtr: Int32
            ) in
                hostBindings.core_array_append(ptr: ptr, value_ptr: valuePtr)
            }

            WasmInstance.Function("array_remove") { [self] (
                ptr: Int32,
                idx: Int32
            ) in
                hostBindings.core_array_remove(ptr: ptr, idx: idx)
            }
        }
    }
}
