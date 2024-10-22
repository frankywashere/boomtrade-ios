//
//  boomtradeApp.swift
//  boomtrade
//
//  Created by Whatsupfranks on 10/22/24.
//

import SwiftUI

@main
struct boomtradeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
