//
//  CoreDB.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//  
//

struct CoreDB: _Shared {
    var dependencies: any Dependencies {
      CoreDBMacros()
    }
}

extension CoreDB: Testable {
  struct Tests: TestTarget {
    var name: String { "CoreDBTests" }

    var dependencies: any Dependencies {
      CoreDB()
      CustomDump()
    }
  }
}
