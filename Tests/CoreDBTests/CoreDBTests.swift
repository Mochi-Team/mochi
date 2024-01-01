//
//  CoreDBTests.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

@testable
import CoreDB
import CustomDump
import XCTest

// MARK: - Error

private enum Error: Swift.Error {
  case structExpected(for: Any.Type)
}

// MARK: - CoreORMTests

final class CoreORMTests: XCTestCase {
  private let core = PersistentCoreDB<TestSchema>()

  override func setUp() async throws {
    try await super.setUp()
    try await core.load()
  }

  override func tearDown() async throws {
    try await super.tearDown()
    try await core.reset()
  }

  func testLoadingDatabase() async throws {
    try await core.load()
  }

  func testResetDatabase() async throws {
    try await core.reset()
  }

  func testCreatingEntity() async throws {
    let parent = Parent(name: "Hello")

    XCTAssertNoDifference(parent.name, "Hello")

    try await core.transaction { context in
      try await context.create(parent)
      try await context.create(parent)
    }

    let parents: [Parent] = try await core.transaction { context in
      try await context.fetch()
    }

    XCTAssertNoDifference(parents.count, 2)
    XCTAssertNoDifference(parents.first?.name, parent.name)
    XCTAssertNoDifference(parents.last?.name, parent.name)

    var parentClone = parents.first.unsafelyUnwrapped
    parentClone.name = "Bro"

    let valueUpdated = try await core.transaction { [parentClone] context in
      try await context.update(parentClone)
    }

    XCTAssertNoDifference(valueUpdated.name, "Bro")

    let parents2: [Parent] = try await core.transaction { context in
      try await context.fetch()
    }

    XCTAssertNoDifference(parents2.count, 2)
    XCTAssertNoDifference(parents2.first?.name, "Bro")
  }

  func testAddingParentNoChild() async throws {
    let parent = Parent(name: "John")

    let updatedParent = try await core.transaction { context in
      try await context.create(parent)
    }

    XCTAssertNoDifference(updatedParent.name, parent.name)
    XCTAssertNoDifference(updatedParent.childOptional, parent.childOptional)
  }

  func testSettingChild() async throws {
    let parent = Parent(name: "John", child: .init(name: "Jonas"))

    try await core.transaction { context in
      try await context.create(parent)
    }

    let fetchedParent: Parent? = try await core.transaction { context in
      try await context.fetch(.all.where(\Parent.name == "John")).first
    }

    XCTAssertNotNil(fetchedParent)
    XCTAssertNoDifference(fetchedParent?.name, parent.name)
    XCTAssertNoDifference(fetchedParent?.child.name, parent.child.name)
  }

  func testAddingChildren() async throws {
    let parent = Parent(name: "John", children: [])

    try await core.transaction { context in
      try await context.create(parent)
    }

    let fetchedParent: Parent? = try await core.transaction { context in
      try await context.fetch(.all.where(\Parent.name == "John")).first
    }

    XCTAssertNotNil(fetchedParent)

    guard var fetchedParent else {
      throw Error.structExpected(for: Parent.self)
    }

    XCTAssertNoDifference(fetchedParent.name, parent.name)
    XCTAssertNoDifference(fetchedParent.children, parent.children)

    for i in 0...10 {
      fetchedParent.children.append(.init(name: "\(i)"))
    }

    let updatedParent = try await core.transaction { [fetchedParent] context in
      try await context.createOrUpdate(fetchedParent)
    }

    XCTAssertNoDifference(updatedParent.children.count, fetchedParent.children.count)
  }
}
