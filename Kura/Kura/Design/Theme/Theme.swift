// Theme.swift
// Design tokens — tipografia, espaçamento, layout
//
// NOTA: As extensões de Color (kuraBackground, kuraAccent etc.) são geradas
// automaticamente pelo Xcode a partir de Design/Theme/Colors.xcassets.
// Não declare Color extensions manualmente aqui — causará redeclaração.

import SwiftUI

// MARK: - Typography

enum KuraFont {
    /// Hiragino Sans — tipografia primária do Kura
    static func primary(size: CGFloat) -> Font {
        .custom("HiraginoSans-W3", size: size)
    }

    static func primaryMedium(size: CGFloat) -> Font {
        .custom("HiraginoSans-W6", size: size)
    }

    static func primaryBold(size: CGFloat) -> Font {
        .custom("HiraginoSans-W8", size: size)
    }

    // Escala tipográfica
    static let title:    Font = primaryMedium(size: 18)
    static let headline: Font = primaryMedium(size: 15)
    static let body:     Font = primary(size: 14)
    static let caption:  Font = primary(size: 12)
    static let micro:    Font = primary(size: 11)
}

// MARK: - Spacing

enum KuraSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Layout

enum KuraLayout {
    static let sidebarWidth:  CGFloat = 260
    static let popoverWidth:  CGFloat = 720
    static let popoverHeight: CGFloat = 520
    static let cornerRadius:  CGFloat = 10
}

// MARK: - Adaptive Background

/// Fundo canônico do Kura — nunca usar Color.kuraBackground.ignoresSafeArea() direto nas views.
/// macOS 26+: transparente (glass chrome automático do NSPopover visível)
/// macOS 15–25: MeshGradient sutil com accent índigo
/// macOS 14: kuraBackground sólido
struct KuraAdaptiveBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if #available(macOS 26, *), !reduceTransparency {
            Color.clear.ignoresSafeArea()
        } else if #available(macOS 15, *), !reduceTransparency {
            KuraMeshBackground().ignoresSafeArea()
        } else {
            Color.kuraBackground.ignoresSafeArea()
        }
    }
}

// MARK: - MeshGradient Background (macOS 15+)

@available(macOS 15, *)
struct KuraMeshBackground: View {
    @ObservedObject private var popoverVisibility = PopoverVisibility.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    /// Anima apenas quando o popover está visível e o usuário não pediu menos movimento.
    private var motionEnabled: Bool { popoverVisibility.isShown && !reduceMotion }

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [animate ? 0.55 : 0.45, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                // Tons escuros de profundidade (intencionalmente mais escuros que
                // kuraBackground; não há token exato para estas sombras de mesh).
                Color(red: 0.06, green: 0.06, blue: 0.10),
                Color(red: 0.08, green: 0.08, blue: 0.14),
                Color(red: 0.06, green: 0.06, blue: 0.10),
                Color(red: 0.09, green: 0.09, blue: 0.14),
                Color.kuraAccent.opacity(0.14),
                Color(red: 0.09, green: 0.09, blue: 0.14),
                Color(red: 0.07, green: 0.07, blue: 0.09),
                Color(red: 0.09, green: 0.09, blue: 0.13),
                Color(red: 0.07, green: 0.07, blue: 0.09),
            ]
        )
        .animation(
            motionEnabled
                ? .easeInOut(duration: 9).repeatForever(autoreverses: true)
                : .default,
            value: animate
        )
        .onChange(of: motionEnabled, initial: true) { _, enabled in
            animate = enabled
        }
    }
}

// MARK: - Liquid Glass (macOS 26+)

/// Fonte única de verdade para a decisão de aplicar Liquid Glass.
/// Glass é macOS 26+ e é desativado sob "Reduzir transparência".
enum KuraGlass {
    static func isActive(reduceTransparency: Bool) -> Bool {
        if #available(macOS 26, *), !reduceTransparency {
            return true
        }
        return false
    }
}

private struct KuraGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let interactive: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26, *), !reduceTransparency {
            content.glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            content
        }
    }
}

extension View {
    /// Aplica Liquid Glass na camada de navegação (macOS 26+, respeita Reduzir
    /// transparência). Per Apple HIG: usar só em chrome de navegação, nunca em conteúdo.
    func kuraGlass(interactive: Bool = false, cornerRadius: CGFloat = KuraLayout.cornerRadius) -> some View {
        modifier(KuraGlassModifier(interactive: interactive, cornerRadius: cornerRadius))
    }
}
