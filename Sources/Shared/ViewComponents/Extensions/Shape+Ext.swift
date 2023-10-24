//
//  Shape+Ext.swift
//
//
//  Created by ErrorErrorError on 10/4/23.
//
//

import Foundation
import SwiftUI

public extension Shape {
    func style(
        withStroke strokeContent: some ShapeStyle,
        lineWidth: CGFloat = 1,
        fill fillContent: some ShapeStyle
    ) -> some View {
        stroke(strokeContent, lineWidth: lineWidth)
            .background(fill(fillContent))
    }
}

// MARK: - RoundedCorners

public struct RoundedCorners: Shape {
    public init(_ radius: CGFloat = 0.0) {
        self.init(topLeading: radius, topTrailing: radius, bottomLeading: radius, bottomTrailing: radius)
    }

    public init(topRadius: CGFloat = 0.0, bottomRadius: CGFloat = 0.0) {
        self.init(topLeading: topRadius, topTrailing: topRadius, bottomLeading: bottomRadius, bottomTrailing: bottomRadius)
    }

    public init(
        topLeading: CGFloat = 0.0,
        topTrailing: CGFloat = 0.0,
        bottomLeading: CGFloat = 0.0,
        bottomTrailing: CGFloat = 0.0
    ) {
        self.tl = topLeading
        self.tr = topTrailing
        self.bl = bottomLeading
        self.br = bottomTrailing
    }

    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        let tr = min(min(tr, h / 2), w / 2)
        let tl = min(min(tl, h / 2), w / 2)
        let bl = min(min(bl, h / 2), w / 2)
        let br = min(min(br, h / 2), w / 2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(
            center: CGPoint(x: w - tr, y: tr),
            radius: tr,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(
            center: CGPoint(x: w - br, y: h - br),
            radius: br,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(
            center: CGPoint(x: bl, y: h - bl),
            radius: bl,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(
            center: CGPoint(x: tl, y: tl),
            radius: tl,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
