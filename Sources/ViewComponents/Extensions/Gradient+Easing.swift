//
//  File.swift
//
//
//  Created by ErrorErrorError on 5/20/23.
//
//
//  Ported from https://github.com/larsenwork/postcss-easing-gradients

import Easing
import Foundation
import RealModule
import SwiftUI

// MARK: - EasingCurveFunction

public struct EasingCurveFunction<T: Real>: Sendable {
    let curve: Easing.Curve<T>
    let function: Function

    public enum Function: Sendable {
        case easeIn
        case easeOut
        case easeInOut
    }

    public init(curve: Easing.Curve<T>, function: Function) {
        self.curve = curve
        self.function = function
    }

    func callAsFunction(_ value: T) -> T {
        switch function {
        case .easeIn:
            return curve.easeIn(value)
        case .easeOut:
            return curve.easeOut(value)
        case .easeInOut:
            return curve.easeInOut(value)
        }
    }
}

public extension Gradient {
    static func easingLinearGradient(
        stops: [Stop],
        easing: EasingCurveFunction<Double> = .init(curve: .cubic, function: .easeIn)
    ) -> Self {
        .init(stops: mixColors(stops, easing))
    }
}

private func mixColors(_ stops: [Gradient.Stop], _ function: EasingCurveFunction<Double>) -> [Gradient.Stop] {
    var steps = [Gradient.Stop]()
    let sortedStops = stops.sorted { $0.location < $1.location }

    if stops.count < 2 {
        return stops
    }

    let blocks = 15

    for idx in 0..<max(0, sortedStops.count - 1) {
        let startStop = sortedStops[idx]
        let endStop = sortedStops[idx + 1]

        let transitionLen = endStop.location - startStop.location
        let stepSize = 1.0 / Double(blocks + 1)

        for section in 0...(blocks + 1) {
            let progress = Double(section) * Double(stepSize)
            let output = function(progress)

            let color = PlatformColor.blend(
                from: .init(startStop.color),
                to: .init(endStop.color),
                amount: output
            )
            steps.append(.init(color: .init(color), location: startStop.location + transitionLen * progress))
        }
    }

    return steps
}
