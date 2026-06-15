//
//  Theme.swift
//  Deep Task
//
//  Created by Stephen Rains on 6/10/26.
//

import SwiftUI
import UIKit

// Shared visual language for the app. A warm, energetic palette built around
// the orange -> red gradient already used by the focus timer.
enum AppTheme {
    // Primary brand accent.
    static let accent = Color.orange

    // Warm brand gradient (orange -> red), used for heroes, rings, and prominent accents.
    static let brandGradient = LinearGradient(
        colors: [.orange, .red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Subtle page background. In light mode this is a flat systemGray6; in dark
    // mode it fades from systemGray6 to systemBackground. The bottom stop is an
    // adaptive color so light mode collapses to a single flat tone.
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(.systemGray6),
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark ? .systemBackground : .systemGray6
            })
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Standard content-card corner radius.
    static let cardCornerRadius: CGFloat = 18

    // Soft elevation shadow for content cards.
    static func cardShadow(_ color: Color = .black) -> Color {
        color.opacity(0.06)
    }
}

// Convenience modifier giving a view the standard rounded "content card" treatment.
extension View {
    func contentCard(
        cornerRadius: CGFloat = AppTheme.cardCornerRadius,
        backgroundColor: Color? = Color(.systemBackground),
        addBorder: Bool = false
    ) -> some View {
        self
            .background(backgroundColor == nil ? Color(.systemBackground) : backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: AppTheme.cardShadow(), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.brandGradient, lineWidth: addBorder ? 2 : 0)
            )
    }
}
