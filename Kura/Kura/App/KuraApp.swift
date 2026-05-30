// KuraApp.swift
// Entry point — menu bar app (no dock icon)

import SwiftUI

@main
struct KuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty: UI is driven entirely by the menu bar extra + AppDelegate
        Settings {
            EmptyView()
        }
    }
}
