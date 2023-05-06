//  CoreData+Request.swift
//  mochi
//
//  Created by ErrorErrorError on 11/16/22.
//
//  Modified version of https://github.com/prisma-ai/Sworm

import CoreData
import Foundation

// MARK: - Request

public struct Request<PlainObject: MORepresentable> {
    var fetchLimit: Int?
    var predicate: NSPredicate?
    var sortDescriptors: [SortDescriptor] = []

    fileprivate init() {}
}

public extension Request {
    func `where`(
        _ predicate: some PredicateProtocol<PlainObject>
    ) -> Self {
        var obj = self
        obj.predicate = predicate
        return obj
    }

    func sort(
        _ keyPath: KeyPath<PlainObject, some Comparable>,
        ascending: Bool = true
    ) -> Self {
        var obj = self
        obj.sortDescriptors.append(
            .init(
                keyPath: keyPath,
                ascending: ascending
            )
        )
        return obj
    }

    func limit(_ count: Int) -> Self {
        var obj = self
        obj.fetchLimit = max(0, count)
        return obj
    }

    static var all: Self {
        .init()
    }
}

extension Request {
    func makeFetchRequest<ResultType: NSFetchRequestResult>(
        ofType resultType: NSFetchRequestResultType = .managedObjectResultType,
        attributesToFetch: Set<Attribute<PlainObject>> = PlainObject.attributes
    ) -> NSFetchRequest<ResultType> {
        let properties = attributesToFetch.filter { !$0.isRelation }.map(\.name)

        let fetchRequest = NSFetchRequest<ResultType>(entityName: PlainObject.entityName)
        fetchRequest.resultType = resultType
        fetchRequest.propertiesToFetch = properties
        fetchRequest.includesPropertyValues = !properties.isEmpty

        fetchLimit.flatMap { fetchRequest.fetchLimit = $0 }
        predicate.flatMap { fetchRequest.predicate = $0 }

        if !sortDescriptors.isEmpty {
            fetchRequest.sortDescriptors = sortDescriptors.map(\.object)
        }

        return fetchRequest
    }
}

// MARK: - SortDescriptor

struct SortDescriptor: Equatable {
    let keyPathString: String
    var ascending = true
}

extension SortDescriptor {
    var object: NSSortDescriptor {
        .init(
            key: keyPathString,
            ascending: ascending
        )
    }
}

extension SortDescriptor {
    init(
        keyPath: KeyPath<some Any, some Any>,
        ascending: Bool
    ) {
        self.keyPathString = NSExpression(forKeyPath: keyPath).keyPath
        self.ascending = ascending
    }
}

// MARK: - PredicateProtocol

public protocol PredicateProtocol<Root>: NSPredicate {
    associatedtype Root: MORepresentable
}

// MARK: - CompoundPredicate

public final class CompoundPredicate<Root: MORepresentable>: NSCompoundPredicate, PredicateProtocol {}

// MARK: - ComparisonPredicate

public final class ComparisonPredicate<Root: MORepresentable>: NSComparisonPredicate, PredicateProtocol {}

// MARK: compound operators

public extension PredicateProtocol {
    static func && (
        lhs: Self,
        rhs: Self
    ) -> CompoundPredicate<Root> {
        CompoundPredicate(type: .and, subpredicates: [lhs, rhs])
    }

    static func || (
        lhs: Self,
        rhs: Self
    ) -> CompoundPredicate<Root> {
        CompoundPredicate(type: .or, subpredicates: [lhs, rhs])
    }

    static prefix func ! (not: Self) -> CompoundPredicate<Root> {
        CompoundPredicate(type: .not, subpredicates: [not])
    }
}

// MARK: - comparison operators

public extension ConvertableValue where Self: Equatable {
    static func == <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .equalTo, value)
    }

    static func != <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .notEqualTo, value)
    }
}

public extension ConvertableValue where Self: Comparable {
    static func > <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .greaterThan, value)
    }

    static func < <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .lessThan, value)
    }

    static func <= <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .lessThanOrEqualTo, value)
    }

    static func >= <R>(
        kp: KeyPath<R, Self>,
        value: Self
    ) -> ComparisonPredicate<R> {
        ComparisonPredicate(kp, .greaterThanOrEqualTo, value)
    }
}

// MARK: - internal

internal extension ComparisonPredicate {
    convenience init<Value: ConvertableValue>(
        _ keyPath: KeyPath<Root, Value>,
        _ op: NSComparisonPredicate.Operator,
        _ value: Value?
    ) {
        let attribute = Root.attribute(keyPath)
        let ex1 = NSExpression(forKeyPath: attribute.name)
        let ex2 = NSExpression(forConstantValue: value?.encode())
        self.init(leftExpression: ex1, rightExpression: ex2, modifier: .direct, type: op)
    }
}
