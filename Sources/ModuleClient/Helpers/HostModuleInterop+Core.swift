//
//  HostModuleInterop+Core.swift
//  
//
//  Created by ErrorErrorError on 5/9/23.
//  
//

import Foundation
import SwiftSoup

// MARK: - Core Imports

extension HostModuleInterop {
    func print(
        string_ptr: Int32,
        string_len: Int32
    ) {
        let string = try? memory.string(byteOffset: .init(string_ptr), length: .init(string_len))
        Swift.print(string ?? "")
    }

    func copy(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }
            return alloc.add(value)
        }
    }

    func destroy(ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
            alloc[ptr] = nil
        }
    }

    func create_array() -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add([AnyHashable?]())
        }
    }

    func create_obj() -> PtrRef {
        self.hostAllocations.withValue { $0.add([AnyHashable: AnyHashable]()) }
    }

    func create_string(buf_ptr: RawPtr, buf_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let string = try memory.string(
                byteOffset: Int(buf_ptr),
                length: Int(buf_len)
            )

            return alloc.add(string)
        }
    }

    func create_bool(value: Int32) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(value != 0)
        }
    }

    func create_float(value: Float64) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(Float(value))
        }
    }

    func create_int(value: Int64) -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.add(Int(value))
        }
    }

    func create_error() -> PtrRef {
        self.hostAllocations.withValue { alloc in
            alloc.addError(.unknown())
        }
    }

    func ptr_kind(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
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

    func string_len(ptr: PtrRef) -> Int32 {
        self.handleErrorAlloc { alloc in
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

    func read_string(ptr: PtrRef, buf_ptr: RawPtr, len: Int32) {
        self.hostAllocations.withValue { alloc in
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

    func read_int(ptr: PtrRef) -> Int64 {
        self.handleErrorAlloc { alloc in
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

    func read_float(ptr: PtrRef) -> Float64 {
        self.handleErrorAlloc { alloc in
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

    func read_bool(ptr: PtrRef) -> Int32 {
        self.handleErrorAlloc { alloc in
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

    func obj_len(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, let obj = alloc[ptr] else {
                return 0
            }

            return Int32((obj as? [String: Any?])?.count ?? 0)
        }
    }

    func obj_get(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func obj_set(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
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

    func obj_remove(ptr: PtrRef, key_ptr: RawPtr, key_len: Int32) {
        self.hostAllocations.withValue { alloc in
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

    func obj_keys(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func obj_values(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func array_len(ptr: PtrRef) -> Int32 {
        self.hostAllocations.withValue { alloc in
            guard ptr >= 0, let array = alloc[ptr] as? [Any?] else {
                return 0
            }

            return Int32(array.count)
        }
    }

    func array_get(ptr: PtrRef, idx: Int32) -> PtrRef {
        self.handleErrorAlloc { alloc in
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

    func array_set(ptr: PtrRef, idx: Int32, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
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

    func array_append(ptr: PtrRef, value_ptr: PtrRef) {
        self.hostAllocations.withValue { alloc in
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

    func array_remove(ptr: PtrRef, idx: Int32) {
        self.hostAllocations.withValue { alloc in
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
