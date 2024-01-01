//
//  Relation.swift
//
//
//  Created by ErrorErrorError on 5/15/23.
//
//

import CoreData
import Foundation

// MARK: - Error

private enum Error: Swift.Error {
  case propertyNotAvailable(forEntity: String, key: String)
  case contextIsNotAvailable
}

// MARK: - Relation

public struct Relation<Model: Entity, DestinationEntity: Entity, Value>: OpaqueRelation, TransformableProperty {
  public typealias Model = Model

  public let name: String?
  public let keyPath: WritableKeyPath<Model, Value>
  public let traits: Set<PropertyTrait>

  let deleteRule: NSDeleteRule
  let isOrdered: Bool
  let encode: (String, Model, NSManagedObject) throws -> Void
  let decode: (String, inout Model, NSManagedObject) throws -> Void
}

extension Relation {
  /// This represents an optional to one relationship
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == DestinationEntity? {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      guard let entity = instance[keyPath: keyPath] else {
        object.setValue(nil, forKey: name)
        return
      }

      if let entityManagedObjectId = entity._$id.objectID {
        try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
      } else {
        let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
          forEntityName: DestinationEntity.entityName,
          into: managedObjectContext
        )
        try entity.encode(to: managedObject.objectID, context: managedObjectContext)
        object.setValue(managedObject, forKey: name)
      }
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willAccessValue(forKey: name)
      defer { object.didAccessValue(forKey: name) }

      let managed = try? cast(object.value(forKey: name), to: NSManagedObject.self)

      instance[keyPath: keyPath] = try managed.flatMap { try .init(id: $0.objectID, context: managedObjectContext) }
    }
  }

  /// This represents to one relationship
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == DestinationEntity {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      let entity = instance[keyPath: keyPath]

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      if let entityManagedObjectId = entity._$id.objectID {
        try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
      } else {
        let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
          forEntityName: DestinationEntity.entityName,
          into: managedObjectContext
        )
        try entity.encode(to: managedObject.objectID, context: managedObjectContext)
        object.setValue(managedObject, forKey: name)
      }
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willAccessValue(forKey: name)
      defer { object.didAccessValue(forKey: name) }

      let managed = try cast(object.value(forKey: name), to: NSManagedObject.self)
      instance[keyPath: keyPath] = try .init(id: managed.objectID, context: managedObjectContext)
    }
  }

  /// This represents an optional to-many relationship set
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == Set<DestinationEntity>? {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      let set = instance[keyPath: keyPath]

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      guard let set else {
        object.setValue(nil, forKey: name)
        return
      }

      let cocoaSet = NSMutableSet()

      try set.forEach { entity in
        if let entityManagedObjectId = entity._$id.objectID {
          try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
          cocoaSet.add(managedObjectContext.object(with: entityManagedObjectId))
        } else {
          let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
            forEntityName: DestinationEntity.entityName,
            into: managedObjectContext
          )
          try entity.encode(to: managedObject.objectID, context: managedObjectContext)
          cocoaSet.add(managedObject)
        }
      }

      object.setValue(cocoaSet, forKey: name)
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willAccessValue(forKey: name)
      defer { object.didAccessValue(forKey: name) }

      instance[keyPath: keyPath] = try Set(
        object.mutableSetValue(forKey: name).compactMap { element in
          try DestinationEntity(
            unmanagedId: cast(element, to: NSManagedObject.self).objectID,
            context: managedObjectContext
          )
        }
      )
    }
  }

  /// This represents to-many relationship set
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == Set<DestinationEntity> {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = false
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName
      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      let cocoaSet = NSMutableSet()

      try instance[keyPath: keyPath].forEach { entity in
        if let entityManagedObjectId = entity._$id.objectID {
          try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
          cocoaSet.add(managedObjectContext.object(with: entityManagedObjectId))
        } else {
          let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
            forEntityName: DestinationEntity.entityName,
            into: managedObjectContext
          )
          try entity.encode(to: managedObject.objectID, context: managedObjectContext)
          cocoaSet.add(managedObject)
        }
      }

      object.setValue(cocoaSet, forKey: name)
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willAccessValue(forKey: name)
      defer { object.didAccessValue(forKey: name) }

      instance[keyPath: keyPath] = try Set(
        object.mutableSetValue(forKey: name).compactMap { element in
          try DestinationEntity(
            unmanagedId: cast(element, to: NSManagedObject.self).objectID,
            context: managedObjectContext
          )
        }
      )
    }
  }

  /// This represents an optional to-many relationship ordered array
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == [DestinationEntity]? {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = true
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      guard let array = instance[keyPath: keyPath] else {
        object.setValue(nil, forKey: name)
        return
      }

      let cocoaArray = NSMutableOrderedSet()

      try array.forEach { entity in
        if let entityManagedObjectId = entity._$id.objectID {
          try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
          cocoaArray.add(managedObjectContext.object(with: entityManagedObjectId))
        } else {
          let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
            forEntityName: DestinationEntity.entityName,
            into: managedObjectContext
          )
          try entity.encode(to: managedObject.objectID, context: managedObjectContext)
          cocoaArray.add(managedObject)
        }
      }

      object.setValue(cocoaArray, forKey: name)
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      instance[keyPath: keyPath] = try object.mutableOrderedSetValue(forKey: name).map { element in
        try DestinationEntity(
          unmanagedId: cast(element, to: NSManagedObject.self).objectID,
          context: managedObjectContext
        )
      }
    }
  }

  /// This represents to-many relationship ordered array
  ///
  public init(
    name: String? = nil,
    isTransient: Bool = false,
    deleteRule: NSDeleteRule = .cascadeDeleteRule,
    _ keyPath: WritableKeyPath<Model, Value>
  ) where Value == [DestinationEntity] {
    self.name = name
    self.traits = isTransient ? [.transient] : []
    self.deleteRule = deleteRule
    self.isOrdered = true
    self.keyPath = keyPath
    self.encode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willChangeValue(forKey: name)
      defer { object.didChangeValue(forKey: name) }

      let cocoaArray = NSMutableOrderedSet()

      try instance[keyPath: keyPath].forEach { entity in
        if let entityManagedObjectId = entity._$id.objectID {
          try entity.encode(to: entityManagedObjectId, context: managedObjectContext)
          cocoaArray.add(managedObjectContext.object(with: entityManagedObjectId))
        } else {
          let managedObject: NSManagedObject = NSEntityDescription.insertNewObject(
            forEntityName: DestinationEntity.entityName,
            into: managedObjectContext
          )
          try entity.encode(to: managedObject.objectID, context: managedObjectContext)
          cocoaArray.add(managedObject)
        }
      }

      object.setValue(cocoaArray, forKey: name)
    }
    self.decode = { memberName, instance, object in
      let name = name ?? memberName

      guard let managedObjectContext = object.managedObjectContext else {
        throw Error.contextIsNotAvailable
      }

      object.willAccessValue(forKey: name)
      defer { object.didAccessValue(forKey: name) }

      instance[keyPath: keyPath] = try object.mutableOrderedSetValue(forKey: name).map { element in
        try DestinationEntity(
          unmanagedId: cast(element, to: NSManagedObject.self).objectID,
          context: managedObjectContext
        )
      }
    }
  }
}

// MARK: - OpaqueRelation

protocol OpaqueRelation: OpaqueProperty {
  associatedtype DestinationEntity: Entity
  var deleteRule: NSDeleteRule { get }
  var isOrdered: Bool { get }
}

// MARK: - RelationType

enum RelationType {
  case toOne
  case toMany
}

extension OpaqueRelation {
  var destinationEntity: DestinationEntity.Type { DestinationEntity.self }

  var relationType: RelationType {
    if Value.self is DestinationEntity.Type {
      .toOne
    } else if Value.self is DestinationEntity?.Type {
      .toOne
    } else {
      .toMany
    }
  }
}
