//
//  StatusView.swift
//
//
//  Created by ErrorErrorError on 12/14/23.
//
//

import Foundation
import SwiftUI

// MARK: - StatusView

@MainActor
public struct StatusView: View {
  public enum ImageType {
    case asset(String, hasBadge: Bool = false)
    case system(String, hasBadge: Bool = false)
  }

  let title: String
  let description: String
  let image: ImageType?
  let foregroundColor: Color

  @MainActor
  public init(
    title: String,
    description: String,
    image: ImageType? = nil,
    foregroundColor: Color = .gray
  ) {
    self.title = title
    self.description = description
    self.image = image
    self.foregroundColor = foregroundColor
  }

  @MainActor public var body: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.medium))

        Text(description)
          .font(.footnote.weight(.regular))
      }

      Spacer()

      if let image {
        Group {
          switch image {
          case let .asset(name, hasBadge):
            Image(name)
              .resizable()
              .scaledToFit()
              .frame(height: hasBadge ? 28 : 18)
          case let .system(name, hasBadge):
            Image(systemName: name)
              .resizable()
              .scaledToFit()
              .frame(height: hasBadge ? 28 : 18)
          }
        }
        .foregroundColor(foregroundColor.opacity(0.8))
      }
    }
    .foregroundColor(foregroundColor)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .style(withStroke: foregroundColor.opacity(0.0), fill: foregroundColor.opacity(0.12))
    }
    .padding(.horizontal)
  }
}

extension StatusView {
  @MainActor
  public init(
    title: String,
    description: String,
    systemImage: String,
    foregroundColor: Color = .gray
  ) {
    self.init(
      title: title,
      description: description,
      image: .system(systemImage),
      foregroundColor: foregroundColor
    )
  }

  @MainActor
  public init(
    title: String,
    description: String,
    assetImage: String,
    foregroundColor: Color = .gray
  ) {
    self.init(
      title: title,
      description: description,
      image: .asset(assetImage),
      foregroundColor: foregroundColor
    )
  }
}
