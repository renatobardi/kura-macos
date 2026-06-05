// LocalNotifier.swift
// Notificações locais via UserNotifications — NÃO exigem conta Apple paga, capability
// nem APNs. É o caminho de entrega enquanto o app (menu bar, sempre aberto) recebe os
// eventos por WebSocket. Ver docs/notifications-spec.md.

import UserNotifications

enum LocalNotifier {
    /// Pede autorização uma vez no launch. Sem isto nenhuma notificação aparece.
    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    print("[LocalNotifier] authorization error: \(error)")
                } else {
                    print("[LocalNotifier] authorization granted: \(granted)")
                }
            }
    }

    /// Dispara a notificação imediatamente (`trigger: nil`).
    static func show(_ payload: PushPayload) {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        content.userInfo = payload.userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[LocalNotifier] failed to schedule notification: \(error)")
            }
        }
    }
}
