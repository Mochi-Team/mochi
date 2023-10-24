//
//  NSPersistentStore+Ext.swift
//
//
//  Created by ErrorErrorError on 5/16/23.
//
//

import CoreData
import Foundation

extension NSPersistentStore {
    func destroy(_ coordinator: NSPersistentStoreCoordinator) throws {
        guard let url else {
            return
        }

        try coordinator.replacePersistentStore(
            at: url,
            destinationOptions: nil,
            withPersistentStoreFrom: url,
            sourceOptions: nil,
            ofType: type
        )

        try coordinator.destroyPersistentStore(
            at: url,
            ofType: type,
            options: nil
        )

        if coordinator.persistentStores.contains(self) {
            try coordinator.remove(self)
        }

        let fileManager = FileManager.default
        let fileDeleteCoordinator = NSFileCoordinator(filePresenter: nil)

        fileDeleteCoordinator.coordinate(
            writingItemAt: url.deletingLastPathComponent(),
            options: .forDeleting,
            error: nil
        ) { url in
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }

            let ckAssetFilesURL = url.deletingLastPathComponent().appendingPathComponent("ckAssetFiles")

            if fileManager.fileExists(atPath: ckAssetFilesURL.path) {
                try? fileManager.removeItem(at: ckAssetFilesURL)
            }
        }
    }
}
