//
//  JSVEnumAssociatedCodable.swift
//
//
//  Created by ErrorErrorError on 11/11/23.
//
//

import Foundation

public protocol JSValueEnumCodingKey: CodingKey {
  static var type: Self { get }
}

// public protocol JSVEnumAssociatedEncodable: Encodable {}
// public protocol JSVEnumAssociatedDecodable: Decodable {}
//
// extension JSVEnumAssociatedEncodable {
// }
//
// public typealias JSVEnumAssociatedCodable = JSVEnumAssociatedEncodable & JSVEnumAssociatedDecodable
