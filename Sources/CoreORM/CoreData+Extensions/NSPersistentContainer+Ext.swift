//
//  File.swift
//  
//
//  Created by ErrorErrorError on 5/15/23.
//  
//

import CoreData
import Foundation

extension NSPersistentContainer {
    @discardableResult
    func schedule<T>(
        _ action: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try Task.checkCancellation()

        let context = newBackgroundContext()
        return try await context.perform(schedule: .immediate) {
            try context.execute(action)
        }
    }

    @MainActor
    func loadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { [unowned self] continuation in
            loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }
}
