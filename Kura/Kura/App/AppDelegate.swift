// AppDelegate.swift
// Configures app as menu bar accessory (no dock icon) and bootstraps Firebase

import AppKit
import Combine
import SwiftUI
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private let notifications = NotificationsClient()
    private var authCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — pure menu bar app
        NSApp.setActivationPolicy(.accessory)

        // TODO(fase-0): FirebaseApp.configure() — descomentar após adicionar Firebase via SPM
        // FirebaseApp.configure()

        setupMenuBar()
        setupNotifications()
    }

    // MARK: - Notifications

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        LocalNotifier.requestAuthorization()

        // Conecta/desconecta o socket de notificações conforme o login. A entrega é local
        // (UserNotifications) a partir de eventos WebSocket — ver docs/notifications-spec.md.
        authCancellable = AuthManager.shared.$authState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                switch state {
                case .signedIn(let userID):
                    self?.notifications.connect(userID: userID)
                case .signedOut, .unknown:
                    self?.notifications.disconnect()
                }
            }
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
        // nil desbloqueia o chrome glass automático do NSPopover no macOS 26.
        if #available(macOS 26, *) { popover.appearance = nil }
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

    private func showPopover() {
        guard let button = statusItem?.button, let popover = popover, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Mostra o banner mesmo com o app em foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Tap na notificação: abre o popover. Roteamento profundo por `data.type`
    /// (item_id/page_id/collector em `response.notification.request.content.userInfo`)
    /// fica para a Fase 4, quando as views de Inbox/Dashboard existirem.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        showPopover()
        completionHandler()
    }
}
