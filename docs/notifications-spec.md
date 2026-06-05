# Spec — Notificações no kura-macos via WebSocket (sem conta Apple paga)

> **Handoff doc.** Escrito na sessão do `kura-server`; destina-se a ser aplicado em uma
> sessão no repo `kura-macos`. O server **já está pronto** para este contrato (ver seção
> "Contrato do server"). Aqui descrevo só o lado do cliente.

## Por que esta abordagem

A conta Apple Developer está travada, o que bloqueava o E2E porque o único caminho de
notificação era **APNs** (push remoto), que **exige conta paga**.

Solução: o app é menu bar (sempre aberto), então não precisa de APNs. O server entrega
notificações em **tempo real por WebSocket** (Phoenix Channel) e o app dispara
**notificações locais** com o framework `UserNotifications` — que **não exigem conta paga**
nem APNs. A Apple sai do caminho crítico. Quando a conta liberar, adiciona-se APNs por cima
**sem mudar** o tratamento do payload (ver "Futuro").

---

## Contrato do server (já implementado — não precisa mexer no kura-server)

- **Socket Phoenix:** `ws(s)://<host>/socket/websocket` (mount `KuraWeb.UserSocket`).
- **Autenticação:** o socket exige o param **`token`** = Firebase **ID token**. O server
  verifica o token (mesma verificação do REST) e deriva `user_id = claims["sub"]`
  (o Firebase uid). Param `user_id` cru **só** é aceito em ambiente de teste.
- **Tópico do canal:** `notifications:<firebase_uid>` (`KuraWeb.NotificationChannel`).
  O join só é autorizado se o uid do tópico for igual ao uid do token. Ou seja:
  **junte-se a `notifications:` + (seu Firebase uid)**.
- **Evento recebido:** `"push"` com payload:

  ```json
  {
    "title": "Needs your attention",
    "body":  "Review this",
    "data":  { "type": "inbox", "item_id": "inbox_items:i1" }
  }
  ```

- **`data.type`** ∈ `"dashboard" | "inbox" | "ingest" | "collector_error"`.
  Campos extras conforme o tipo: `item_id` (inbox), `page_id` (ingest),
  `collector` (collector_error). `title`/`body` sempre presentes.
- Eventos que disparam push hoje no server: **novo item de inbox** (`Inbox.create`) e
  **dashboard diário gerado** (`DashboardWorker`).

> **Nota de integração importante:** o tópico usa o **Firebase uid** (claims `sub`). O
> identificador que o server passa em `notify/2` precisa ser esse mesmo uid para o broadcast
> casar com o tópico que o app assina. (Para inbox via API autenticada isso já bate, pois
> vem de `current_user.uid`.)

---

## Lado do cliente (kura-macos) — o que implementar

### 1. Rodar o app localmente sem conta paga

- macOS **permite rodar o app localmente** assinando com um **Apple ID grátis** (Personal
  Team) no Xcode → Signing & Capabilities. O limite de expiração de 7 dias é só **iOS**;
  para um app Mac rodando na sua própria máquina não há esse bloqueio.
- **Não** habilite a capability "Push Notifications" (essa exige conta paga / APNs).
  Notificações **locais** não precisam de capability nem de membership.

### 2. Notificações locais (`UserNotifications`)

```swift
import UserNotifications

enum LocalNotifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                // log granted/error
            }
    }

    static func show(title: String, body: String, userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // entrega imediata
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

- Chame `requestAuthorization()` no launch (uma vez).
- Para a notificação aparecer com o app em foreground, implemente
  `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`
  retornando `[.banner, .sound]`.

### 3. Conexão WebSocket ao Phoenix Channel

Recomendado usar **SwiftPhoenixClient** (SPM: `https://github.com/davidstump/SwiftPhoenixClient`),
que já implementa o protocolo Phoenix (join, refs, heartbeat, reconnect). Esqueleto:

```swift
import SwiftPhoenixClient
import FirebaseAuth

final class NotificationsSocket {
    private var socket: Socket?
    private var channel: Channel?

    func connect() async {
        guard let user = Auth.auth().currentUser else { return }
        let token = try? await user.idToken()          // Firebase ID token
        let uid = user.uid

        // Passe o token como param de conexão do socket.
        let socket = Socket("wss://<host>/socket/websocket",
                            params: ["token": token ?? ""])
        socket.onError { error, _ in /* log + backoff */ }
        socket.connect()

        let channel = socket.channel("notifications:\(uid)")
        channel.on("push") { message in
            let p = message.payload
            let title = p["title"] as? String ?? ""
            let body  = p["body"]  as? String ?? ""
            let data  = p["data"]  as? [AnyHashable: Any] ?? [:]
            LocalNotifier.show(title: title, body: body, userInfo: data)
        }
        channel.join()
            .receive("ok")    { _ in /* joined */ }
            .receive("error") { _ in /* topic/uid mismatch ou token inválido */ }

        self.socket = socket
        self.channel = channel
    }
}
```

> Se preferir não adicionar dependência, dá para usar `URLSessionWebSocketTask` cru, mas aí
> você precisa montar o protocolo Phoenix à mão: frames JSON
> `{ "topic", "event", "payload", "ref", "join_ref" }`, enviar `"phx_join"`, responder
> `"heartbeat"` periodicamente. **SwiftPhoenixClient é fortemente recomendado.**

### 4. Token / refresh

- O **ID token Firebase expira (~1h)**. Pegue sempre via `user.idToken()` (que renova
  automaticamente) **antes de (re)conectar**. Em reconexão, reconstrua o `Socket` com um
  token fresco (o token vai nos params da conexão, não dá pra trocar sem reconectar).
- Reconecte em: perda de rede, app acordando de sleep, e após expiração (trate
  `socket.onError`/close com backoff exponencial).

### 5. Info.plist / ATS

- **Produção:** use `wss://` (TLS) — sem ajustes de ATS.
- **Dev local** contra `ws://127.0.0.1:4000`: adicione exceção ATS para localhost ou use
  `wss://` via túnel. Não relaxe ATS em produção.

---

## Futuro — quando a conta Apple Developer liberar

- O payload e o tratamento no app **não mudam**.
- Adiciona-se: capability "Push Notifications", registro do device token APNs, e um endpoint
  no server para salvar o token (a tabela `devices` já existe). O server passará a enviar
  **também** via `PigeonNotifier` (APNs) para entrega quando o app estiver fechado.
- O caminho por canal continua sendo o de tempo real com o app aberto.

---

## Checklist de E2E (com o server rodando)

1. `iex -S mix phx.server` no kura-server (com `FIREBASE_PROJECT_ID` setado e SurrealDB up).
2. App macOS: autentica no Firebase, pede autorização de notificações, conecta o socket com
   `token`, junta-se a `notifications:<uid>`.
3. Disparo de teste no iex do server:
   - Inbox: `Kura.Inbox.create("<uid>", %{title: "Olá do server", kind: "suggestion"})`
   - Dashboard: enfileirar/rodar `Kura.Workers.DashboardWorker` para `<uid>`.
4. Esperado: o app recebe o evento `"push"` e exibe a notificação local no macOS.

> Para provar só o server (sem o app), no iex:
> `KuraWeb.Endpoint.subscribe("notifications:<uid>")` e depois
> `Kura.Notifications.notify_dashboard("<uid>", %{summary: "oi"})` → `flush()` deve mostrar
> um `%Phoenix.Socket.Broadcast{event: "push", ...}`.
