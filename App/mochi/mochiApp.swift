//
//  mochiApp.swift
//  mochi
//
//  Created by ErrorErrorError on 3/24/23.
//  
//

import SwiftUI

@main
struct mochiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
