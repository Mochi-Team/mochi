//
//  CoreDB.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

// MARK: - CoreDB

struct CoreDB: _Shared {
    var dependencies: any Dependencies {
        CoreDBMacros()
    }
}

// MARK: Testable

extension CoreDB: Testable {
    struct Tests: TestTarget {
        var name: String { "CoreDBTests" }

        var dependencies: any Dependencies {
            CoreDB()
            CustomDump()
        }
    }
}
