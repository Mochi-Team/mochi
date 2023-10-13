//
//  Function.swift
//
//
//  Created by ErrorErrorError on 4/7/23.
//
//

import Foundation

// MARK: - WasmInstance.Function

public extension WasmInstance {
    struct Function {
        public typealias ImportHandler = (UnsafeMutablePointer<UInt64>?, UnsafeMutableRawPointer?) -> UnsafeRawPointer?

        let name: String
        let handler: ImportHandler
        let signature: String

        init(
            name: String,
            signature: String,
            handler: @escaping ImportHandler
        ) {
            self.name = name
            self.signature = signature
            self.handler = handler
        }
    }
}

public extension WasmInstance.Function {
    init<each T: WasmValue>(
        _ name: String,
        _ block: @escaping (repeat each T) throws -> Void
    ) {
        self.init(
            name: name,
            signature: Signature.parse((repeat (each T).self))
        ) { stack, _ in
            var arguments = ArgumentExtractor(hasReturn: false)
            do {
                let args = try arguments.extract(from: stack, (repeat (each T).self))
                try block(repeat (each args))
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }

    init<each T: WasmValue, R: WasmValue>(
        _ name: String,
        _ block: @escaping (repeat each T) throws -> R
    ) {
        self.init(
            name: name,
            signature: Signature.parse((repeat (each T).self), ret: R.wasmType)
        ) { stack, _ in
            var arguments = ArgumentExtractor(hasReturn: true)
            do {
                let args = try arguments.extract(from: stack, (repeat (each T).self))
                let ret = try block(repeat (each args))
                try arguments.push(value: ret, to: stack)
                return nil
            } catch {
                return importedFunctionInternalError
            }
        }
    }
}

let importedFunctionInternalError = UnsafeRawPointer(UnsafeMutableRawPointer.allocate(
    byteCount: _importedFunctionInternalError.count,
    alignment: MemoryLayout<CChar>.alignment
))
private let _importedFunctionInternalError = "ImportedFunctionInternalError".utf8CString
