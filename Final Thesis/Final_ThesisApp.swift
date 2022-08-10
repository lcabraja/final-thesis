//
//  Final_ThesisApp.swift
//  Final Thesis
//
//  Created by doss on 8/10/22.
//

import SwiftUI

@main
struct Final_ThesisApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
