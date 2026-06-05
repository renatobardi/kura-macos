// PushPayload.swift
// Modela o evento "push" do NotificationChannel (ver docs/notifications-spec.md).
// O payload chega como [String: Any] do SwiftPhoenixClient — parse defensivo aqui.

import Foundation

/// Categoria da notificação (`data.type`). Determina o roteamento de deep-link na Fase 4.
enum PushType: String {
    case dashboard
    case inbox
    case ingest
    case collectorError = "collector_error"
}

struct PushPayload {
    let title: String
    let body: String
    let type: PushType?

    /// Campos extras conforme `type` (ver contrato do server).
    let itemID: String?   // inbox
    let pageID: String?   // ingest
    let collector: String?  // collector_error

    /// Repassado cru para `UNNotificationContent.userInfo` — sobrevive ao tap para
    /// roteamento posterior.
    let userInfo: [AnyHashable: Any]

    /// `title`/`body` são sempre enviados pelo server; a ausência indica payload malformado.
    init?(payload: [String: Any]) {
        guard let title = payload["title"] as? String,
              let body = payload["body"] as? String else {
            print("[PushPayload] descartado — title/body ausentes: \(payload)")
            return nil
        }

        let data = payload["data"] as? [String: Any] ?? [:]

        self.title = title
        self.body = body
        self.type = (data["type"] as? String).flatMap(PushType.init(rawValue:))
        self.itemID = data["item_id"] as? String
        self.pageID = data["page_id"] as? String
        self.collector = data["collector"] as? String
        self.userInfo = data
    }
}
