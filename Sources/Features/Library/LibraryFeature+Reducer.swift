//
//  LibraryFeature+Reducer.swift
//
//
//  Created ErrorErrorError on 1/2/24.
//  Copyright © 2024. All rights reserved.
//

import Architecture
import ComposableArchitecture

extension LibraryFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .view:
        break

      case .internal:
        break

      case .delegate:
        break
      }
      return .none
    }
  }
}
