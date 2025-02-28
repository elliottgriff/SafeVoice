//
//  SafeVoiceApp.swift
//  SafeVoice
//
//  Created by Elliott Griffin on 2/28/25.
//

import SwiftUI

@main
struct SafeVoiceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
