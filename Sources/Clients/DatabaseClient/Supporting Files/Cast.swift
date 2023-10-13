//
//  Case.swift
//
//
//  Created by ErrorErrorError on 5/16/23.
//
//

import Foundation

// MARK: - CastError

enum CastError: Swift.Error {
    case failureToCast(object: Any.Type, to: Any.Type)
}

func cast<T, R>(_ value: T, to _: R.Type = R.self) throws -> R {
    guard let result = value as? R else {
        throw CastError.failureToCast(object: T.self, to: R.self)
    }

    return result
}
