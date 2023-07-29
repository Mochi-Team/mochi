//
//  HostBindings+Core.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SwiftSoup

// MARK: - Core Imports

extension HostBindings {
    func core_copy(ptr: PtrRef) -> PtrRef {
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

    func core_destroy(ptr: PtrRef) {
        hostAllocations.withValue { alloc in
            alloc[ptr] = nil
        }
    }

    func core_create_array() -> PtrRef {
        hostAllocations.withValue { alloc in
            alloc.add([AnyHashable?]())
        }
    }

    func core_create_obj() -> PtrRef {
        hostAllocations.withValue { $0.add([AnyHashable: AnyHashable]()) }
    }

    func core_create_string(buf_ptr: RawPtr, buf_len: Int32) -> PtrRef {
        handleErrorAlloc { alloc in
            let string = try memory.string(
                byteOffset: Int(buf_ptr),
                length: Int(buf_len)
            )

            return alloc.add(string)
        }
    }

    func core_create_bool(value: Int32) -> PtrRef {
        hostAllocations.withValue { alloc in
            alloc.add(value != 0)
        }
    }

    func core_create_float(value: Float64) -> PtrRef {
        hostAllocations.withValue { alloc in
            alloc.add(Float(value))
        }
    }

    func core_create_int(value: Int64) -> PtrRef {
        hostAllocations.withValue { alloc in
            alloc.add(Int(value))
        }
    }

    func core_create_error() -> PtrRef {
        hostAllocations.withValue { alloc in
            alloc.addError(.unknown())
        }
    }

    func core_ptr_kind(ptr: PtrRef) -> Int32 {
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
            } else if value is SwiftSoup.Element || value is SwiftSoup.Elements {
                return PtrKind.node.rawValue
            }
            return PtrKind.unknown.rawValue
        }
    }

    func core_string_len(ptr: PtrRef) -> Int32 {
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

    func core_read_string(ptr: PtrRef, buf_ptr: RawPtr, len: Int32) {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, len >= 0 else {
                return
            }

            guard let string = alloc[ptr] as? String, len <= string.utf8.count else {
                return
            }

            try? memory.write(
                with: string.utf8.dropLast(string.utf8.count - Int(len)),
                byteOffset: Int(buf_ptr)
            )
        }
    }

    func core_read_int(ptr: PtrRef) -> Int64 {
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

    func core_read_float(ptr: PtrRef) -> Float64 {
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

    func core_read_bool(ptr: PtrRef) -> Int32 {
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

    func core_obj_len(ptr: PtrRef) -> Int32 {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, let obj = alloc[ptr] else {
                return 0
            }

            return Int32((obj as? [String: Any?])?.count ?? 0)
        }
    }

    func core_obj_get(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) -> PtrRef {
        handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let obj = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            let key = try memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
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

    func core_obj_set(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32, value_ptr: PtrRef) {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, var obj = alloc[ptr] as? [String: Any?] else {
                return
            }

            guard value_ptr >= 0, let value = alloc[value_ptr] else {
                return
            }

            guard let key = try? memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            ) else {
                return
            }

            obj[key] = value
            alloc[ptr] = obj
        }
    }

    func core_obj_remove(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, var obj = alloc[ptr] as? [String: Any?] else {
                return
            }

            guard let key = try? memory.string(
                byteOffset: Int(key_ptr),
                length: Int(key_len)
            ) else {
                return
            }

            obj[key] = nil
            alloc[ptr] = obj
        }
    }

    func core_obj_keys(ptr: PtrRef) -> PtrRef {
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

    func core_obj_values(ptr: PtrRef) -> PtrRef {
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

    func core_array_len(ptr: PtrRef) -> Int32 {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, let array = alloc[ptr] as? [Any?] else {
                return 0
            }

            return Int32(array.count)
        }
    }

    func core_array_get(ptr: PtrRef, idx: Int32) -> PtrRef {
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

    func core_array_set(ptr: PtrRef, idx: Int32, value_ptr: PtrRef) {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, idx >= 0, value_ptr >= 0 else {
                return
            }

            guard var array = alloc[ptr] as? [Any?] else {
                return
            }

            guard let value = alloc[value_ptr] else {
                return
            }

            if idx < array.count {
                array[Int(idx)] = value
                alloc[ptr] = array
            }
        }
    }

    func core_array_append(ptr: PtrRef, value_ptr: PtrRef) {
        hostAllocations.withValue { alloc in
            guard ptr >= 0, value_ptr >= 0 else {
                return
            }

            guard var array = alloc[ptr] as? [Any?] else {
                return
            }

            guard let value = alloc[value_ptr] else {
                return
            }

            array.append(value)
            alloc[ptr] = array
        }
    }

    func core_array_remove(ptr: PtrRef, idx: Int32) {
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
