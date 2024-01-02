//
//  Library.swift
//
//
//  Created by ErrorErrorError on 1/1/24.
//
//

import CoreDB
import Foundation

@Entity
struct Collection {
  var title = ""
  var entries = [Entry]()
}
