//  DesignTokens.swift
//  SuppliScan — Design System (Phase 2)
//
//  Single source of truth for the premium redesign: colour, typography, spacing,
//  radii, elevation, motion, glass and iconography. See docs/DESIGN_SYSTEM.md for the
//  reasoning behind every decision.
//
//  Design thesis: "clinical confidence with tactile craft."
//  Near-monochrome ink on warm surfaces, ONE brand colour (clinical jade-green), the
//  tier safety spectrum as the only other semantic colour, SF Pro for prose with
//  monospaced DIGITS for data, one coherent spring-driven motion language, and native
//  iOS 26 Liquid Glass confined to the functional (chrome) layer.
//
//  This namespace (`Theme`) is the new source of truth. The legacy `AppTheme` enum
//  remains until each screen is migrated, then it is removed.

import SwiftUI
import UIKit

// MARK: - Namespace

enum Theme {}

// MARK: - Colour

extension Theme {
    /// Semantic palette. Every colour is a dynamic light/dark pair built in code
    /// (no asset catalog), with a high-contrast branch for Accessibility > Increase Contrast.
    enum Palette {

        // Surfaces — warm off-white in light, near-black with a hair of warmth in dark.
        static let surface        = dyn(0xF6F5F2, 0x0B0B0C)   // app background
        static let surfaceRaised  = dyn(0xFFFFFF, 0x171719)   // cards, sheets
        static let surfaceSunken  = dyn(0xEDEBE6, 0x060607)   // wells, insets, fields
        static let surfaceOverlay = dyn(0xFFFFFF, 0x202023)   // popovers, raised overlays

        // Ink — near-monochrome text hierarchy.
        static let ink          = dyn(0x16181C, 0xF4F4F5)     // primary text
        static let inkSecondary = dyn(0x5B6068, 0xA6A7AD)     // secondary text
        static let inkTertiary  = dyn(0x8B909A, 0x6C6D74)     // captions, units
        static let inkFaint     = dyn(0xB6BAC2, 0x46474D)     // placeholders, disabled

        // Brand — clinical jade-green. The single identity/interactive colour.
        static let brand        = dynC(0x0C7C68, 0x2FD6B6, hcLight: 0x065848, hcDark: 0x57F0CF)
        static let brandPressed = dyn(0x0A6657, 0x27B89C)     // pressed/active brand
        static let brandMuted   = dyn4(0x0C7C68, 0.12, 0x2FD6B6, 0.16)  // tinted fills/wells
        static let onBrand      = dyn(0xFFFFFF, 0x05140F)     // text/icons on brand fill

        // Tier safety spectrum — the ONLY other semantic colour. Always paired with text.
        static let tier1     = dynC(0x1F9D57, 0x44D17E, hcLight: 0x107A3F, hcDark: 0x67E89A)  // high / safe
        static let tier2     = dynC(0xBE8400, 0xF0B73D, hcLight: 0x946600, hcDark: 0xFFCE63)  // caution-low
        static let tier3     = dynC(0xD2692A, 0xFF9F5A, hcLight: 0xA84E16, hcDark: 0xFFB67E)  // caution-high
        static let tier4     = dynC(0xCC463B, 0xFF6B5E, hcLight: 0xA32C22, hcDark: 0xFF8C82)  // critical
        static let aiInferred = dynC(0x6E56CF, 0xAB9CF2, hcLight: 0x4E36B0, hcDark: 0xC4BAF7) // AI-inferred (violet)

        // Hairlines / borders — ink at low alpha (separators, card strokes).
        static let hairline       = dyn4(0x16181C, 0.08, 0xFFFFFF, 0.10)
        static let hairlineStrong = dyn4(0x16181C, 0.14, 0xFFFFFF, 0.16)

        // Scrim — for full-screen camera chrome / modal dimming.
        static let scrim = Color.black.opacity(0.55)
    }
}

/// Ergonomic leading-dot access in ShapeStyle contexts: `.foregroundStyle(.brand)`,
/// `.fill(.surfaceRaised)`, `.tint(.brand)`.
extension ShapeStyle where Self == Color {
    static var surface: Color        { Theme.Palette.surface }
    static var surfaceRaised: Color  { Theme.Palette.surfaceRaised }
    static var surfaceSunken: Color  { Theme.Palette.surfaceSunken }
    static var surfaceOverlay: Color { Theme.Palette.surfaceOverlay }
    static var ink: Color            { Theme.Palette.ink }
    static var inkSecondary: Color   { Theme.Palette.inkSecondary }
    static var inkTertiary: Color    { Theme.Palette.inkTertiary }
    static var inkFaint: Color       { Theme.Palette.inkFaint }
    static var brand: Color          { Theme.Palette.brand }
    static var brandPressed: Color   { Theme.Palette.brandPressed }
    static var brandMuted: Color     { Theme.Palette.brandMuted }
    static var onBrand: Color        { Theme.Palette.onBrand }
    static var hairline: Color       { Theme.Palette.hairline }
    static var hairlineStrong: Color { Theme.Palette.hairlineStrong }
}

// MARK: - Spacing (4-pt grid)

extension Theme {
    enum Space {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48

        /// Standard horizontal screen margin. Generous, editorial.
        static let screen: CGFloat = 20
        /// Vertical rhythm between major sections.
        static let section: CGFloat = 28
    }
}

// MARK: - Radius (continuous corners)

extension Theme {
    enum Radius {
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let card: CGFloat = 22   // premium content card — larger than system 10pt
        static let lg:  CGFloat = 28
        static let pill: CGFloat = 999
    }

    /// Continuous (squircle) rounded rect — the only corner style used in the app.
    static func roundedRect(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

// MARK: - Typography
//
// SF Pro for all prose (neutral, precise — NOT monospaced/rounded, which read as
// developer-tool or consumer-wellness). Data and figures use proportional SF Pro with
// `.monospacedDigit()` for tabular alignment without the techy feel. Prose styles are
// built on semantic `Font.TextStyle`s so they scale with Dynamic Type; the two large
// "data hero" sizes are fixed for visual control and clamped at call sites.
// Weights are restrained to .light / .regular / .medium / .semibold.

extension Font {
    // Prose hierarchy (Dynamic Type aware)
    static let dsDisplay  = Font.system(.largeTitle, design: .default).weight(.semibold) // screen heroes
    static let dsTitle    = Font.system(.title2,    design: .default).weight(.semibold)  // card / section titles
    static let dsHeadline = Font.system(.headline).weight(.semibold)                     // row primary
    static let dsBody     = Font.system(.body)                                           // content
    static let dsCallout  = Font.system(.callout)                                        // secondary content
    static let dsSubhead  = Font.system(.subheadline).weight(.medium)                    // labels
    static let dsCaption  = Font.system(.caption)                                        // captions, units
    static let dsEyebrow  = Font.system(.caption2).weight(.semibold)                     // UPPERCASE eyebrow

    // Data / numerics — proportional SF Pro with monospaced digits.
    static let dsHero      = Font.system(size: 46, weight: .light).monospacedDigit()     // the one big number
    static let dsStat      = Font.system(size: 24, weight: .regular).monospacedDigit()   // secondary stats
    static let dsDataBody  = Font.system(.body).monospacedDigit()                        // inline data (mg, %)
    static let dsDataLabel = Font.system(.subheadline).weight(.medium).monospacedDigit()
}

extension Theme {
    /// Named text styles carrying font + tracking + case. Apply with `.textStyle(_:)`.
    enum TypeStyle {
        case display, title, headline, body, callout, subhead, caption, eyebrow
        case hero, stat, dataBody, dataLabel

        var font: Font {
            switch self {
            case .display:  return .dsDisplay
            case .title:    return .dsTitle
            case .headline: return .dsHeadline
            case .body:     return .dsBody
            case .callout:  return .dsCallout
            case .subhead:  return .dsSubhead
            case .caption:  return .dsCaption
            case .eyebrow:  return .dsEyebrow
            case .hero:     return .dsHero
            case .stat:     return .dsStat
            case .dataBody: return .dsDataBody
            case .dataLabel: return .dsDataLabel
            }
        }

        var tracking: CGFloat {
            switch self {
            case .display:  return -0.5
            case .title:    return -0.3
            case .headline: return -0.2
            case .hero:     return -1.0
            case .stat:     return -0.4
            case .eyebrow:  return 0.8     // uppercase label spacing
            default:        return 0
            }
        }

        var isUppercased: Bool { self == .eyebrow }
    }

    enum Icon {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 28
        static let xl: CGFloat = 40
    }
}

extension View {
    /// Apply a design-system text style (font, tracking, case).
    func textStyle(_ style: Theme.TypeStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
            .textCase(style.isUppercased ? .uppercase : nil)
    }
}

// MARK: - Elevation
//
// Philosophy: soft ambient elevation in light mode; in dark mode shadows are nearly
// invisible, so depth comes from lighter surface fills + hairline borders. This modifier
// adapts automatically.

extension Theme {
    enum Elevation { case none, card, raised, floating }
}

private struct ElevationModifier: ViewModifier {
    let level: Theme.Elevation
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        switch (level, scheme) {
        case (.none, _):
            content
        case (.card, .light):
            content.shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        case (.raised, .light):
            content.shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        case (.floating, .light):
            content
                .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        // Dark mode: minimal shadow; depth handled by surface fills + hairlines.
        case (.floating, .dark):
            content.shadow(color: .black.opacity(0.40), radius: 24, x: 0, y: 12)
        case (_, .dark):
            content.shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        @unknown default:
            content
        }
    }
}

extension View {
    func elevation(_ level: Theme.Elevation) -> some View {
        modifier(ElevationModifier(level: level))
    }
}

// MARK: - Motion
//
// One spring vocabulary for the whole app. Specific response/damping values — never the
// opaque `.bouncy`/`.smooth` presets. Springs preferred over duration easings for
// anything interactive or spatial; durations reserved for fades and cross-dissolves.

extension Animation {
    /// Navigation, sheets, large spatial moves. Settled, confident, no overshoot.
    static let dsPrimary = Animation.spring(response: 0.42, dampingFraction: 0.82)
    /// Buttons, toggles, selection. Quick and crisp.
    static let dsSnappy  = Animation.spring(response: 0.30, dampingFraction: 0.80)
    /// Emphasis moments (scan capture, success). A touch of life.
    static let dsBouncy  = Animation.spring(response: 0.48, dampingFraction: 0.66)
    /// Content entrances / large reveals. Smooth, no overshoot.
    static let dsGentle  = Animation.spring(response: 0.58, dampingFraction: 0.92)
    /// Press states, chips, micro-interactions.
    static let dsMicro   = Animation.spring(response: 0.22, dampingFraction: 0.86)

    // Non-spring easings for fades / cross-dissolves.
    static let dsFadeQuick = Animation.easeOut(duration: 0.18)
    static let dsFade      = Animation.easeInOut(duration: 0.26)
}

extension Theme {
    enum Motion {
        /// Stagger step for sequential entrance animations.
        static let stagger: Double = 0.05
    }
}

// MARK: - Glass (iOS 26 Liquid Glass — functional layer only)
//
// Per Apple HIG, Liquid Glass lives in the functional layer (tab bar, floating actions,
// nav chrome, transient overlays) — never on content. These helpers centralise the tint
// and shape so glass reads consistently across the app.

extension View {
    /// Interactive brand-tinted glass for the primary floating action (scan).
    func glassAction(in shape: some Shape = Capsule()) -> some View {
        glassEffect(.regular.tint(Theme.Palette.brand.opacity(0.85)).interactive(), in: shape)
    }

    /// Neutral interactive glass for secondary chrome controls.
    func glassControl(in shape: some Shape = Capsule()) -> some View {
        glassEffect(.regular.interactive(), in: shape)
    }
}

// MARK: - Colour construction helpers

/// Dynamic light/dark colour from two hex literals.
private func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
    })
}

/// Dynamic colour with explicit high-contrast variants.
private func dynC(_ light: UInt32, _ dark: UInt32, hcLight: UInt32, hcDark: UInt32) -> Color {
    Color(uiColor: UIColor { tc in
        let high = tc.accessibilityContrast == .high
        switch (tc.userInterfaceStyle, high) {
        case (.dark, true):  return UIColor(rgb: hcDark)
        case (.dark, false): return UIColor(rgb: dark)
        case (_, true):      return UIColor(rgb: hcLight)
        case (_, false):     return UIColor(rgb: light)
        }
    })
}

/// Dynamic colour with per-mode alpha (for tinted fills).
private func dyn4(_ light: UInt32, _ la: CGFloat, _ dark: UInt32, _ da: CGFloat) -> Color {
    Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(rgb: dark).withAlphaComponent(da)
            : UIColor(rgb: light).withAlphaComponent(la)
    })
}

private extension UIColor {
    convenience init(rgb hex: UInt32) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue:  CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
