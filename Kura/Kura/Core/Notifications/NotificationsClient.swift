// NotificationsClient.swift
// Encapsula o Phoenix Socket + Channel de notificações (papel do ChannelClient previsto
// no CLAUDE.md, escopado a notificações). Conecta a notifications:<uid>, escuta "push" e
// dispara notificações locais. Ver docs/notifications-spec.md.

import Foundation
import SwiftPhoenixClient
// import FirebaseAuth  // TODO(fase-firebase): descomentar para o path de token de produção

@MainActor
final class NotificationsClient {
    private var socket: Socket?
    private var channel: Channel?
    private var currentUserID: String?

    /// Conecta o socket e junta-se a `notifications:<userID>`. Idempotente para o mesmo
    /// userID — reconectar não derruba uma sessão saudável.
    func connect(userID: String) {
        guard currentUserID != userID else { return }
        disconnect()
        currentUserID = userID

        // Params lidos via closure: o SwiftPhoenixClient a reexecuta a cada (re)conexão,
        // então o token sempre vai fresco sem reconstruir o Socket.
        let socket = Socket(KuraEndpoint.socketURL, paramsClosure: {
            // DEBUG: o server em test env aceita `user_id` cru — destrava o E2E sem a
            // conta Apple paga (Firebase ainda desativado). Ver docs/notifications-spec.md.
            ["user_id": userID]

            // TODO(fase-firebase): em produção o server exige o Firebase ID token e deriva
            // o uid de claims["sub"]. Trocar por:
            //   guard let token = AuthManager.shared.firebaseIDToken else { return nil }
            //   return ["token": token]
            // O idToken Firebase expira (~1h); buscá-lo via user.idToken() (renova sozinho)
            // e deixar esta closure devolver o valor fresco a cada reconexão.
        })

        socket.onError { error, _ in
            print("[NotificationsClient] socket error: \(error)")
        }
        socket.onClose {
            print("[NotificationsClient] socket closed")
        }

        let channel = socket.channel("notifications:\(userID)")
        channel.on("push") { message in
            guard let payload = PushPayload(payload: message.payload) else { return }
            // UNUserNotificationCenter é thread-safe; entrega direto.
            LocalNotifier.show(payload)
        }

        channel.join()
            .receive("ok") { _ in
                print("[NotificationsClient] joined notifications:\(userID)")
            }
            .receive("error") { response in
                // token/uid mismatch ou token inválido
                print("[NotificationsClient] join error: \(response.payload)")
            }

        socket.connect()

        self.socket = socket
        self.channel = channel
    }

    func disconnect() {
        channel?.leave()
        socket?.disconnect()
        channel = nil
        socket = nil
        currentUserID = nil
    }
}
