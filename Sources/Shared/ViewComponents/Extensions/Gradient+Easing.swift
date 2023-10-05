//
//  Gradient+Easing.swift
//
//
//  Created by ErrorErrorError on 5/20/23.
//
//
//

import Foundation
import SwiftUI

// MARK: - Easing

public enum Easing: Equatable, Sendable {
    case ease
    case easeIn
    case easeOut
    case easeInOut
    case cubicBezier(CGPoint, CGPoint)
}

public extension Gradient {
    init(
        colors: [Color],
        easing: Easing
    ) {
        self.init(
            stops: colors.enumerated().map { index, color in
                .init(color: color, location: index == colors.count - 1 ? 1.0 : Double(index) / Double(colors.count - 1))
            },
            easing: easing
        )
    }

    init(
        stops: [Gradient.Stop],
        easing: Easing
    ) {
        guard stops.count >= 2 else {
            self.init(stops: stops)
            return
        }

        var newStops = [Gradient.Stop]()

        let steps = 15
        let stepSize = 1.0 / Double(steps)

        let stops = stops.sorted { $0.location < $1.location }

        for currentStop in 0..<max(0, stops.count - 1) {
            let firstStop = stops[currentStop]
            let secondStop = stops[currentStop + 1]

            let transitionLength = secondStop.location - firstStop.location

            // Applies easing in between each color
            for step in 0..<steps {
                let stepPosition = Double(step) * stepSize
                let point = easing(stepPosition)

//                print("from: \(firstStop.location), to: \(secondStop.location), step: \(step), stepPosition: \(stepPosition), point: \(point)")

                let color = PlatformColor.blend(
                    from: .init(firstStop.color),
                    to: .init(secondStop.color),
                    amount: point.y
                )

                newStops.append(
                    .init(
                        color: .init(color),
                        location: (point.x * transitionLength) + firstStop.location
                    )
                )
            }

            // Moves color location based on curve
//            for step in 0...steps {
//                let stepPosition = Double(step) * stepSize
//                let curvePosition = (transitionLength * stepPosition) + firstStop.location
//                let point = easing(curvePosition)
//
//                print("from: \(firstStop.location), to: \(secondStop.location), step: \(step), stepPosition: \(stepPosition), curve: \(curvePosition), point: \(point)")
//
//                let color = PlatformColor.blend(
//                    from: .init(firstStop.color),
//                    to: .init(secondStop.color),
//                    amount: (point.y - firstStop.location) / transitionLength
//                )
//
//                newStops.append(
//                    .init(
//                        color: .init(color),
//                        location: point.x
//                    )
//                )
//            }

            if currentStop == stops.count - 2 {
                newStops.append(secondStop)
            }
        }

        self.init(stops: newStops)
    }
}

// MARK: - Private

private extension Easing {
    var points: (CGPoint, CGPoint) {
        switch self {
        case .ease:
            return (.init(x: 0.25, y: 0.1), .init(x: 0.25, y: 1))
        case .easeIn:
            return (.init(x: 0.42, y: 0), .init(x: 1, y: 1))
        case .easeOut:
            return (.init(x: 0, y: 0), .init(x: 0.58, y: 1))
        case .easeInOut:
            return (.init(x: 0.42, y: 0), .init(x: 0.58, y: 1))
        case let .cubicBezier(point, point2):
            return (point.clamped(), point2.clamped())
        }
    }

    func callAsFunction(@Clamped _ progress: Double) -> CGPoint {
        let (point, point2) = points
        return .init(x: curve(progress, point.x, point2.x), y: curve(progress, point.y, point2.y))
    }
}

private func curve(@Clamped _ pos: Double, @Clamped _ point1: Double, @Clamped _ point2: Double) -> Double {
    3 * pow(1 - pos, 2) * pos * point1 +
        3 * (1 - pos) * pow(pos, 2) * point2 +
        pow(pos, 3)
}

// MARK: - Clamped

@propertyWrapper
private struct Clamped {
    private var value: Double

    var wrappedValue: Double {
        get { value }
        set { value = min(max(newValue, 0.0), 1.0) }
    }

    init(wrappedValue: Double) {
        self.value = wrappedValue
    }
}

private extension CGPoint {
    func clamped() -> CGPoint {
        .init(x: min(max(x, 0.0), 1.0), y: min(max(y, 0.0), 1.0))
    }
}
