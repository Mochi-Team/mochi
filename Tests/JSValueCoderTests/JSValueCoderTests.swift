//
//  JSValueCoderTests.swift
//  
//
//  Created by ErrorErrorError on 11/7/23.
//  
//

import JavaScriptCore
@testable import JSValueCoder
import XCTest

final class JSValueCoderTests: XCTestCase {
    private struct Rectangle: Codable, Equatable {
        let length: Double
    }

    private struct Square: Codable, Equatable {
        let height: Double
        let width: Double
    }

    private enum Shape: Codable, Equatable {
        case rectangle(Rectangle)
        case square(Square)

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            switch try container.decode(String.self, forKey: .type) {
            case "rectangle":
                self = .rectangle(try container.decode(Rectangle.self, forKey: .attributes))
            case "square":
                self = .square(try container.decode(Square.self, forKey: .attributes))
            default:
                fatalError("Unhandled type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .rectangle(rectangle):
                try container.encode("rectangle", forKey: .type)
                try container.encode(rectangle, forKey: .attributes)
            case let .square(square):
                try container.encode("square", forKey: .type)
                try container.encode(square, forKey: .attributes)
            }
        }

        enum CodingKeys: String, CodingKey {
            case attributes
            case type
        }
    }

    func testJSONEncoderPerformance() throws {
        let square = Square(height: 5_000_000_000_000.0, width: 5_000_000_000_000.0)
        let jsonEncoder = JSONEncoder()

        self.measure {
            let data = try? jsonEncoder.encode(square)
            assert(data != nil)
        }
    }

    func testJSValueEncoderPerformance() throws {
        let context = JSContext().unsafelyUnwrapped
        let square = Square(height: 5_000_000_000_000.0, width: 5_000_000_000_000.0)
        let jsValueEncoder = JSValueEncoder()

        self.measure {
            let jsValue = try? jsValueEncoder.encode(square, into: context)
            assert(jsValue != nil)
        }

    }
}
