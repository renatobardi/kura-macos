// AppDelegate.swift
// Configures app as menu bar accessory (no dock icon) and bootstraps Firebase

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — pure menu bar app
        NSApp.setActivationPolicy(.accessory)

        // TODO(fase-0): FirebaseApp.configure() — descomentar após adicionar Firebase via SPM
        // FirebaseApp.configure()

        setupMenuBar()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Kura")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 720, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: RootView()
        )
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
