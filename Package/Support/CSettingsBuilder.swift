//
//  CSettingsBuilder.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

@resultBuilder
enum CSettingsBuilder {
  static func buildPartialBlock(first: CSetting) -> [CSetting] {
    [first]
  }

  static func buildPartialBlock(accumulated: [CSetting], next: CSetting) -> [CSetting] {
    accumulated + [next]
  }
}
