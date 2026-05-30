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
