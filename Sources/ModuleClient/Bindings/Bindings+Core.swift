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

// swiftlint:disable closure_parameter_position cyclomatic_complexity function_body_length
extension ModuleClient.Instance {
    func coreImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "core") {
            WasmInstance.Function("copy") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard let value = alloc[ptr] else {
                        throw ModuleClient.Error.nullPtr()
                    }
                    return alloc.add(value)
                }
            }

            WasmInstance.Function("destroy") { [self] (ptr: Int32) in
                hostAllocations.withValue { alloc in
                    alloc[ptr] = nil
                }
            }

            WasmInstance.Function("create_array") { [self] () -> Int32 in
                hostAllocations.withValue { alloc in
                    alloc.add([AnyHashable?]())
                }
            }

            WasmInstance.Function("create_obj") { [self] in
                hostAllocations.withValue { $0.add([AnyHashable: AnyHashable]()) }
            }

            WasmInstance.Function("create_string") { [self] (
                bufPtr: RawPtr,
                bufLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let string = try memory.string(
                        byteOffset: Int(bufPtr),
                        length: Int(bufLen)
                    )

                    return alloc.add(string)
                }
            }

            WasmInstance.Function("create_bool") { [self] (
                value: Int32
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    alloc.add(value != 0)
                }
            }

            WasmInstance.Function("create_float") { [self] (
                value: Float64
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    alloc.add(Float(value))
                }
            }

            WasmInstance.Function("create_int") { [self] (
                value: Int64
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    alloc.add(Int(value))
                }
            }

            WasmInstance.Function("create_error") { [self] () -> Int32 in
                hostAllocations.withValue { alloc in
                    alloc.addError(.unknown())
                }
            }

            WasmInstance.Function("ptr_kind") { [self] (
                ptr: PtrRef
            ) -> PtrKind.RawValue in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0 else {
                        return PtrKind.null.rawValue
                    }

                    let value = alloc[ptr]

                    if value == nil || value is NSNull {
                        return PtrKind.null.rawValue
                    } else if value is Int || value is Float || value is NSNumber {
                        return PtrKind.number.rawValue
                    } else if value is String {
                        return PtrKind.string.rawValue
                    } else if value is Bool {
                        return PtrKind.bool.rawValue
                    } else if value is [Any?] {
                        return PtrKind.array.rawValue
                    } else if value is [String: Any?] || (value as? KVAccess) != nil {
                        return PtrKind.object.rawValue
                    // TODO: Add support for dictionary key-value pairs
//                    } else if value is [AnyHashable: AnyHashable] {
//                        return PtrKind.dictionary.rawValue
                    } else if value is SwiftSoup.Element || value is SwiftSoup.Elements {
                        return PtrKind.node.rawValue
                    }
                    return PtrKind.unknown.rawValue
                }
            }

            WasmInstance.Function("string_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard alloc[ptr] != nil else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard let string = alloc[ptr] as? String else {
                        throw ModuleClient.Error.castError()
                    }

                    return Int32(string.utf8.count)
                }
            }

            WasmInstance.Function("read_string") { [self] (
                ptr: Int32,
                bufPtr: Int32,
                bufLen: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, bufLen >= 0 else {
                        return
                    }

                    guard let string = alloc[ptr] as? String, bufLen <= string.utf8.count else {
                        return
                    }

                    try? memory.write(
                        with: string.utf8.dropLast(string.utf8.count - Int(bufLen)),
                        byteOffset: Int(bufPtr)
                    )
                }
            }

            WasmInstance.Function("read_int") { [self] (
                ptr: Int32
            ) -> Int64 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return Int64(ptr)
                    }

                    guard let value = alloc[ptr] else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    if let int = value as? Int {
                        return Int64(int)
                    } else if let float = value as? Float {
                        return Int64(float)
                    } else if let int = Int(value as? String ?? "Error") {
                        return Int64(int)
                    } else if let bool = value as? Bool {
                        return Int64(bool ? 1 : 0)
                    } else if let number = value as? NSNumber {
                        return number.int64Value
                    }

                    throw ModuleClient.Error.castError()
                }
            }

            WasmInstance.Function("read_float") { [self] (
                ptr: Int32
            ) -> Float64 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return .init(ptr)
                    }

                    guard let value = alloc[ptr] else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    if let float = value as? Float {
                        return Float64(float)
                    } else if let int = value as? Int {
                        return Float64(int)
                    } else if let float = Float(value as? String ?? "Error") {
                        return Float64(float)
                    } else if let bool = value as? Bool {
                        return Float64(bool ? 1 : 0)
                    } else if let number = value as? NSNumber {
                        return Float64(number.doubleValue)
                    }

                    throw ModuleClient.Error.castError()
                }
            }

            WasmInstance.Function("read_bool") { [self] (
                ptr: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0, let value = alloc[ptr] else {
                        return 0
                    }

                    if let bool = value as? Bool {
                        return Int32(bool ? 1 : 0)
                    } else if let value = value as? Int {
                        return Int32(value != 0 ? 1 : 0)
                    } else if let value = value as? Float {
                        return Int32(value != 0 ? 1 : 0)
                    }
                    return 0
                }
            }

            WasmInstance.Function("obj_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, let obj = alloc[ptr] else {
                        return 0
                    }

                    return Int32((obj as? [String: Any?])?.count ?? 0)
                }
            }

            WasmInstance.Function("obj_get") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard let obj = alloc[ptr] else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    let key = try memory.string(
                        byteOffset: Int(keyPtr),
                        length: Int(keyLen)
                    )

                    if let obj = obj as? [String: Any?], let value = obj[key] {
                        return alloc.add(value)
                    } else if let obj = obj as? KVAccess, let value = obj[key] {
                        return alloc.add(value)
                    } else {
                        throw ModuleClient.Error.castError()
                    }
                }
            }

            WasmInstance.Function("obj_set") { [self] (
                ptr: PtrRef,
                keyPtr: RawPtr,
                keyLen: Int32,
                valuePtr: PtrRef
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, var obj = alloc[ptr] as? [String: Any?] else {
                        return
                    }

                    guard valuePtr >= 0, let value = alloc[valuePtr] else {
                        return
                    }

                    guard let key = try? memory.string(
                        byteOffset: Int(keyPtr),
                        length: Int(keyLen)
                    ) else {
                        return
                    }

                    obj[key] = value
                    alloc[ptr] = obj
                }
            }

            WasmInstance.Function("obj_remove") { [self] (
                ptr: Int32,
                keyPtr: Int32,
                keyLen: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, var obj = alloc[ptr] as? [String: Any?] else {
                        return
                    }

                    guard let key = try? memory.string(
                        byteOffset: Int(keyPtr),
                        length: Int(keyLen)
                    ) else {
                        return
                    }

                    obj[key] = nil
                    alloc[ptr] = obj
                }
            }

            WasmInstance.Function("obj_keys") { [self] (
                ptr: PtrRef
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard alloc[ptr] != nil else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard let obj = alloc[ptr] as? [String: Any?] else {
                        throw ModuleClient.Error.castError()
                    }

                    return alloc.add(Array(obj.keys))
                }
            }

            WasmInstance.Function("obj_values") { [self] (
                ptr: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard alloc[ptr] != nil else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard let obj = alloc[ptr] as? [String: Any?] else {
                        throw ModuleClient.Error.castError()
                    }

                    return alloc.add(Array(obj.values))
                }
            }

            WasmInstance.Function("array_len") { [self] (
                ptr: Int32
            ) -> Int32 in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, let array = alloc[ptr] as? [Any?] else {
                        return 0
                    }

                    return Int32(array.count)
                }
            }

            WasmInstance.Function("array_get") { [self] (
                ptr: PtrRef,
                idx: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    guard idx >= 0 else {
                        throw ModuleClient.Error.indexOutOfBounds()
                    }

                    guard alloc[ptr] != nil else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    guard let array = alloc[ptr] as? [Any?] else {
                        throw ModuleClient.Error.castError()
                    }

                    if array.indices.contains(Int(idx)) {
                        return alloc.add(array[Int(idx)])
                    }

                    throw ModuleClient.Error.indexOutOfBounds()
                }
            }

            WasmInstance.Function("array_set") { [self] (
                ptr: Int32,
                idx: Int32,
                valuePtr: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, idx >= 0, valuePtr >= 0 else {
                        return
                    }

                    guard var array = alloc[ptr] as? [Any?] else {
                        return
                    }

                    guard let value = alloc[valuePtr] else {
                        return
                    }

                    if idx < array.count {
                        array[Int(idx)] = value
                        alloc[ptr] = array
                    }
                }
            }

            WasmInstance.Function("array_append") { [self] (
                ptr: Int32,
                valuePtr: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, valuePtr >= 0 else {
                        return
                    }

                    guard var array = alloc[ptr] as? [Any?] else {
                        return
                    }

                    guard let value = alloc[valuePtr] else {
                        return
                    }

                    array.append(value)
                    alloc[ptr] = array
                }
            }

            WasmInstance.Function("array_remove") { [self] (
                ptr: Int32,
                idx: Int32
            ) in
                hostAllocations.withValue { alloc in
                    guard ptr >= 0, idx >= 0 else {
                        return
                    }

                    guard var array = alloc[ptr] as? [Any?] else {
                        return
                    }

                    if idx < array.count {
                        array.remove(at: Int(idx))
                        alloc[ptr] = array
                    }
                }
            }
        }
    }
}
