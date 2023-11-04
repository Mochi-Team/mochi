//
//  Exports.swift
//
//
//  Created by ErrorErrorError on 4/4/23.
//
//

import CWasm3
import Foundation

// MARK: - WasmInstance.Exports

public extension WasmInstance {
    @dynamicMemberLookup
    final class Exports {
        private let _runtime: IM3Runtime

        init(runtime: IM3Runtime) {
            self._runtime = runtime
        }

        public func isFunctionAvailable(for name: String) -> Bool {
            (try? function(name: name)) != nil
        }
    }
}

extension WasmInstance.Exports {
    private func call(
        _ functionName: String,
        _ args: [any WasmValue]
    ) throws {
        try args.map(\.description).withCStrings { ptr in
            var cStrings = ptr
            let function = try self.function(name: functionName)
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            defer { size.deallocate() }
            let result = wasm3_CallWithArgs(
                function,
                UInt32(args.count),
                &cStrings,
                size,
                nil
            )
            if let result {
                throw WasmInstance.Error.functions(.onCallFunction(String(cString: result)))
            } else if size.pointee != 0 {
                throw WasmInstance.Error.functions(.invalidFunctionReturnType)
            } else {
                return
            }
        }
    }

    private func call<R: WasmValue>(
        _ functionName: String,
        _ args: [any WasmValue]
    ) throws -> R {
        try args.map(\.description).withCStrings { ptr in
            var cStrings = ptr
            let function = try function(name: functionName)
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            defer { size.deallocate() }
            let output = UnsafeMutablePointer<R>.allocate(capacity: 1)
            defer { output.deallocate() }
            let result = wasm3_CallWithArgs(
                function,
                UInt32(args.count),
                &cStrings,
                size,
                output
            )
            if let result {
                throw WasmInstance.Error.functions(.onCallFunction(String(cString: result)))
            } else if MemoryLayout<R>.size != size.pointee {
                throw WasmInstance.Error.functions(.invalidFunctionReturnType)
            } else {
                let output = output.pointee
                return output
            }
        }
    }

    private func function(name: String) throws -> IM3Function {
        var function: IM3Function?

        let result = m3_FindFunction(&function, _runtime, name)
        guard let function, result == nil else {
            throw WasmInstance.Error.functions(
                .failedToFindFunction(
                    named: name,
                    error: result.flatMap { String(cString: $0) } ?? ""
                )
            )
        }
        return function
    }
}

public extension WasmInstance.Exports {
    subscript(dynamicMember member: String) -> (_ args: any WasmValue...) throws -> Void {
        { try self.call(member.snake_case(), $0) }
    }

    subscript<R: WasmValue>(dynamicMember member: String) -> (_ args: any WasmValue...) throws -> R {
        { try self.call(member.snake_case(), $0) }
    }
}

private extension String {
    func snake_case() -> String {
        var result = ""

        for index in indices {
            let char = self[index]
            if char.isUppercase {
                let newChar = char.lowercased()

                if index != startIndex, index != endIndex {
                    result += "_"
                }
                result += newChar
            } else {
                result += String(char)
            }
        }
        return result
    }
}
