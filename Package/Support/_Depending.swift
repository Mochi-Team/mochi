//
// _Depending.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

protocol _Depending {
  @DependencyBuilder
  var dependencies: any Dependencies { get }
}

extension _Depending {
  var dependencies: any Dependencies {
    [Dependency]()
  }
}

extension _Depending {
  func allDependencies() -> [Dependency] {
    self.dependencies.compactMap {
      $0 as? _Depending
    }
    .flatMap {
      $0.allDependencies()
    }
    .appending(self.dependencies)
  }
}
