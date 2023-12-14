//
//  Module+.swift
//
//
//  Created by ErrorErrorError on 11/12/23.
//
//

import Foundation

extension Module {
  public var mainJSFile: URL {
    directory.appendingPathComponent("main")
      .appendingPathExtension("js")
  }
}
