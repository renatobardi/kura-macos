// PopoverVisibility.swift
// Rastreia se o popover da menu bar está visível, para que as views possam
// pausar animações ambiente enquanto o popover está oculto (economia de bateria).

import Combine

final class PopoverVisibility: ObservableObject {
    static let shared = PopoverVisibility()
    @Published var isShown = false
    private init() {}
}
