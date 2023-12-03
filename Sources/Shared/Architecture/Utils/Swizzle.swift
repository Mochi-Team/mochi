//
//  Swizzle.swift
//
//
//  Created by ErrorErrorError on 12/2/23.
//  
//  Source: https://gist.github.com/Amzd/01e1f69ecbc4c82c8586dcd292b1d30d

import Foundation
import LoggerClient

public struct Swizzle {
    @discardableResult
    public init(
        _ type: AnyClass,
        @SwizzleSelectorsBuilder builder: () -> [SwizzleReplacer]
    ) {
        builder().forEach { $0(type) }
    }
}

public struct SwizzleReplacer {
    let original: Selector
    let swizzled: Selector

    func callAsFunction(_ type: AnyClass) {
        guard let originalMethod = class_getInstanceMethod(type, original),
              let swizzledMethod = class_getInstanceMethod(type, swizzled) else {
            logger.warning("Failed to swizzle: #selector(\(self.original.description)) => #selector(\(self.swizzled.description))")
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

@resultBuilder
public enum SwizzleSelectorsBuilder {
    public typealias Component = SwizzleReplacer

    public static func buildPartialBlock(first: [Component]) -> [Component] { first }
    public static func buildPartialBlock(first: Component) -> [Component] { [first] }
    public static func buildPartialBlock(accumulated: [Component], next: Component) -> [Component] { accumulated + [next] }
    public static func buildPartialBlock(accumulated: [Component], next: [Component]) -> [Component] { accumulated + next }

    public static func buildBlock(_ components: Component...) -> [Component] { components }
    public static func buildEither(first component: Component) -> [Component] { [component] }
    public static func buildEither(second component: Component) -> [Component] { [component] }

    public static func buildBlock(_ components: [Component]...) -> [Component] { components.flatMap { $0 } }
    public static func buildEither(first component: [Component]) -> [Component] { component }
    public static func buildEither(second component: [Component]) -> [Component] { component }
    public static func buildOptional(_ component: [Component]?) -> [Component] { component ?? [] }

    public static func buildLimitedAvailability(_ component: [Component]) -> [Component] { component }
}

infix operator =>

public extension Selector {
    static func => (original: Selector, swizzled: Selector) -> SwizzleReplacer {
        .init(original: original, swizzled: swizzled)
    }
}
