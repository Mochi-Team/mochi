//
//  File.swift
//
//
//  Created by ErrorErrorError on 3/26/23.
//
//

import Foundation

typealias Lock = NSLock

extension NSLock {
    @discardableResult
    func locked<R>(_ operation: () throws -> R) rethrows -> R {
        lock()
        defer { self.unlock() }
        return try operation()
    }
}
