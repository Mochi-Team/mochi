//
//  CoreORMTests.swift
//
//
//  Created by ErrorErrorError on 5/17/23.
//
//

@testable
import CoreORM
import XCTest

final class CoreORMTests: XCTestCase {
    private let core = CoreORM<TestSchema>()

    func testLoadingDatabase() async throws {
        try await core.load()
    }

    func testResetDatabase() async throws {
        try await core.reset()
    }

    override func setUp() async throws {
        try await super.setUp()
        try await core.load()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await core.reset()
    }

    func testCreatingEntity() async throws {
        let parent = Parent(name: "Hello")

        XCTAssertEqual(parent.name, "Hello")

        try await core.transaction { context in
            try await context.create(parent)
            try await context.create(parent)
        }

        let parents: [Parent] = try await core.transaction { context in
            try await context.fetch()
        }

        XCTAssertEqual(parents.count, 2)
        XCTAssertEqual(parents.first?.name, parent.name)
        XCTAssertEqual(parents.last?.name, parent.name)

        var parentClone = parents.first.unsafelyUnwrapped
        parentClone.name = "Bro"

        let valueUpdated = try await core.transaction { [parentClone] context in
            try await context.update(parentClone)
        }

        XCTAssertEqual(valueUpdated.name, "Bro")

        let parents2: [Parent] = try await core.transaction { context in
            try await context.fetch()
        }

        XCTAssertEqual(parents2.count, 2)
        XCTAssertEqual(parents2.first?.name, "Bro")
    }

    func testAddingParentNoChild() async throws {
        let parent = Parent(name: "John", childOptional: nil)

        let updatedParent = try await core.transaction { context in
            try await context.create(parent)
        }

        XCTAssertEqual(updatedParent.name, parent.name)
        XCTAssertEqual(updatedParent.childOptional, parent.childOptional)
    }

    func testAddingChildItems() async throws {
        let parent = Parent(name: "John", child: .init(name: "Jonas"))

        try await core.transaction { context in
            try await context.create(parent)
        }

        let fetchedParent: Parent? = try await core.transaction { context in
            try await context.fetch(.all.where(\Parent.$name == "John")).first
        }

        XCTAssertNotNil(fetchedParent)
        XCTAssertEqual(fetchedParent?.name, parent.name)
        XCTAssertEqual(fetchedParent?.child.name, parent.child.name)
    }
}
