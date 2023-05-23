//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/19/23.
//  
//

import CoreORM
import Foundation

public protocol SomeRequest {
    init()

    associatedtype SomeEntity: Entity
}

extension SomeRequest {
    func entityType() -> SomeEntity.Type {
        SomeEntity.self
    }

    public var all: Self {
        .init()
    }
}

public struct AnyRequest {
    let entity: Entity.Type
    let request: Any

    init<T: Entity>(_ request: Request<T>) {
        self.entity = T.self
        self.request = request
    }
}

extension Request {
    func eraseToAnyRequest() -> AnyRequest {
        .init(self)
    }
}
