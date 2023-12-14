//
//  ElasticParallaxView.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import Foundation
import SwiftUI

// MARK: - ElasticParallaxView

struct ElasticParallaxView: ViewModifier {
  func body(content: Content) -> some View {
    GeometryReader { reader in
      let minY = reader.frame(in: .global).minY
      content
        .frame(
          width: reader.size.width,
          height: reader.size.height + (minY > 0 ? minY : 0),
          alignment: .top
        )
        .contentShape(Rectangle())
        .clipped()
        .offset(y: minY < 0 ? 0 : -minY)
    }
  }
}

extension View {
  @ViewBuilder
  public func elasticParallax(_ enable: Bool = true) -> some View {
    if enable {
      modifier(ElasticParallaxView())
    } else {
      self
    }
  }
}
