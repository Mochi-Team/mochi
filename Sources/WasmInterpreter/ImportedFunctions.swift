//
//  ImportedFunctions.swift
//
//
//  Created by ErrorErrorError on 4/5/23.
//
//

import CWasm3
import Foundation

private let lock = NSLock()
var lastInstanceIdentifier: UInt64 = 0
var importedFunctionCache = [UInt64: [UnsafeMutableRawPointer: WasmInstance.Function.ImportHandler]]()

var nextInstanceIdentifier: UInt64 {
    lock.locked {
        lastInstanceIdentifier += 1
        return lastInstanceIdentifier
    }
}

func importedFunction(
    for userData: UnsafeMutableRawPointer?,
    instanceIdentifier id: UInt64
) -> WasmInstance.Function.ImportHandler? {
    guard let context = userData else {
        return nil
    }
    return lock.locked { importedFunctionCache[id]?[context] }
}

func setImportedFunction(
    _ function: @escaping WasmInstance.Function.ImportHandler,
    for context: UnsafeMutableRawPointer,
    instanceIdentifier id: UInt64
) {
    lock.locked {
        if var functionsForID = importedFunctionCache[id] {
            functionsForID[context] = function
            importedFunctionCache[id] = functionsForID
        } else {
            let functionsForID = [context: function]
            importedFunctionCache[id] = functionsForID
        }
    }
}

func removeImportedFunction(
    for context: UnsafeMutableRawPointer,
    instanceIdentifier id: UInt64
) {
    lock.locked {
        guard var functionsForID = importedFunctionCache[id] else {
            return
        }
        functionsForID.removeValue(forKey: context)
        importedFunctionCache[id] = functionsForID
    }
}

func removeImportedFunctions(forInstanceIdentifier id: UInt64) {
    lock.locked {
        _ = importedFunctionCache.removeValue(forKey: id)
    }
}

func handleImportedFunction(
    _ runtime: UnsafeMutablePointer<M3Runtime>?,
    _ context: UnsafeMutablePointer<M3ImportContext>?,
    _ stackPointer: UnsafeMutablePointer<UInt64>?,
    _ heap: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    guard let id = m3_GetUserData(runtime)?.load(as: UInt64.self) else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    guard let userData = context?.pointee.userdata else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    guard let function = importedFunction(
        for: userData,
        instanceIdentifier: id
    ) else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    return function(stackPointer, heap)
}

extension NSLock {
    func locked<R>(_ block: () -> R) -> R {
        lock()
        defer { self.unlock() }
        return block()
    }
}
