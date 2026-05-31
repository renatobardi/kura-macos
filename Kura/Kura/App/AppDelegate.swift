// AppDelegate.swift
// Configures app as menu bar accessory (no dock icon) and bootstraps Firebase

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
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
        popover.contentSize = NSSize(width: KuraLayout.popoverWidth, height: KuraLayout.popoverHeight)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: RootView()
        )
        self.popover = popover
    }

    // MARK: - NSPopoverDelegate

    func popoverDidShow(_ notification: Notification) {
        PopoverVisibility.shared.isShown = true
    }

    func popoverDidClose(_ notification: Notification) {
        PopoverVisibility.shared.isShown = false
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
