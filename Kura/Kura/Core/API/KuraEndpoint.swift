// KuraEndpoint.swift
// Fonte única do endereço do kura-server. Toda a camada de rede lê daqui.

import Foundation

enum KuraEndpoint {
    /// URL do Phoenix socket (`KuraWeb.UserSocket`, mount `/socket/websocket`).
    /// DEBUG aponta para o server local; produção usa TLS (`wss://`).
    static var socketURL: String {
        #if DEBUG
        return "ws://127.0.0.1:4000/socket/websocket"
        #else
        // TODO(fase-firebase): trocar pelo host real do kura-server em produção.
        return "wss://api.oute.pro/socket/websocket"
        #endif
    }
}
