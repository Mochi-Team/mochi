import CWasm3
import Foundation

// MARK: - Managing imported functions

func setImportedFunction(
    _ function: @escaping ImportedFunctionSignature,
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

func importedFunction(
    for userData: UnsafeMutableRawPointer?,
    instanceIdentifier id: UInt64
) -> ImportedFunctionSignature? {
    guard let context = userData else {
        return nil
    }
    return lock.locked { importedFunctionCache[id]?[context] }
}

func handleImportedFunction(
    _ runtime: UnsafeMutablePointer<M3Runtime>?,
    _ context: UnsafeMutablePointer<M3ImportContext>?,
    _ stackPointer: UnsafeMutablePointer<UInt64>?,
    _ heap: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    guard let id = m3_GetUserData(runtime)?.load(as: UInt64.self)
    else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    guard let userData = context?.pointee.userdata
    else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    guard let function = importedFunction(for: userData, instanceIdentifier: id)
    else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    return function(stackPointer, heap)
}

// MARK: - Generating instance identifiers

var nextInstanceIdentifier: UInt64 {
    lock.locked {
        lastInstanceIdentifier += 1
        return lastInstanceIdentifier
    }
}

func makeRawPointer(for id: UInt64) -> UnsafeMutableRawPointer {
    let ptr = UnsafeMutableRawPointer.allocate(
        byteCount: MemoryLayout<UInt64>.size,
        alignment: MemoryLayout<UInt64>.alignment
    )
    ptr.storeBytes(of: id, as: UInt64.self)
    return ptr
}

// MARK: - Private

private let lock = Lock()
private var lastInstanceIdentifier: UInt64 = 0
private var importedFunctionCache = [UInt64: [UnsafeMutableRawPointer: ImportedFunctionSignature]]()
