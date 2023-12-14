//
//  CircularProgressView.swift
//
//
//  Created by ErrorErrorError on 5/5/23.
//
//

import Foundation
import SwiftUI

// MARK: - CircularProgressView

public struct CircularProgressView<BarColor: ShapeStyle, Accessory: View>: View {
  public struct BarStyle {
    public init(
      fill: BarColor,
      width: CGFloat = 12,
      blurRadius: CGFloat = 4
    ) {
      self.fill = fill
      self.width = width
      self.blurRadius = blurRadius
    }

    let fill: BarColor
    let width: CGFloat
    let blurRadius: CGFloat
  }

  private let progress: Double
  private let barStyle: BarStyle
  private let accessory: () -> Accessory

  public init(
    progress: Double,
    barStyle: BarStyle,
    @ViewBuilder accessory: @escaping () -> Accessory
  ) {
    self.progress = progress
    self.barStyle = barStyle
    self.accessory = accessory
  }

  private var clampedProgress: Double {
    max(0.0, min(1.0, progress))
  }

  public var body: some View {
    ZStack {
      ArcShape(percentage: 1.0)
        .stroke(
          style: .init(
            lineWidth: barStyle.width,
            lineCap: .round
          )
        )
        .fill(Color.gray.opacity(0.2))

      ArcShape(percentage: clampedProgress)
        .stroke(
          style: .init(
            lineWidth: barStyle.width,
            lineCap: .round
          )
        )
        .fill(barStyle.fill)
        .blur(radius: barStyle.blurRadius)

      ArcShape(percentage: clampedProgress)
        .stroke(
          style: .init(
            lineWidth: barStyle.width,
            lineCap: .round
          )
        )
        .fill(barStyle.fill)

      accessory()
    }
    .aspectRatio(contentMode: .fit)
    .padding(barStyle.width / 2)
  }
}

extension CircularProgressView {
  public init(
    progress: Double,
    barStyle: BarStyle
  ) where Accessory == EmptyView {
    self.init(
      progress: progress,
      barStyle: barStyle
    ) {
      EmptyView()
    }
  }
}

// MARK: - ArcShape

struct ArcShape: Shape {
  let percentage: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addArc(
      center: .init(
        x: rect.width / 2.0,
        y: rect.height / 2.0
      ),
      radius: rect.height / 2.0,
      startAngle: .degrees(-90.0),
      endAngle: .degrees(360.0 * Double(percentage) - 90.0),
      clockwise: false
    )
    return path
  }
}

// MARK: - CircularProgressView_Previews

#Preview {
  CircularProgressView(
    progress: 0.5,
    barStyle: .init(fill: Color.blue, width: 12, blurRadius: 4)
  )
  .padding()
}
