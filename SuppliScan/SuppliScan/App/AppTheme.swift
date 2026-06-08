// AppTheme.swift
// SuppliScan
// Design tokens — single source of truth for colors, spacing, and nutrient avatars.

import SwiftUI
import UIKit

enum AppTheme {

    // MARK: - Colors

    enum Color {
        // RDI safety spectrum
        static let rdiSafe    = SwiftUI.Color(.systemGreen)
        static let rdiWarning = SwiftUI.Color(.systemOrange)
        static let rdiDanger  = SwiftUI.Color(.systemRed)
        static let rdiNoData  = SwiftUI.Color(.secondaryLabel)

        // Tier badges (bioavailability / form quality)
        static let tier1 = SwiftUI.Color(.systemGreen)
        static let tier2 = SwiftUI.Color(.systemYellow)
        static let tier3 = SwiftUI.Color(.systemOrange)
        static let tier4 = SwiftUI.Color(.systemRed)

        // Status
        static let success    = SwiftUI.Color(.systemGreen)
        static let warning    = SwiftUI.Color(.systemOrange)
        static let critical   = SwiftUI.Color(.systemRed)
        static let unresolved = SwiftUI.Color(.systemYellow)

        // Camera chrome
        static let scanChrome = SwiftUI.Color.white

        // MARK: Nutrient avatar backgrounds

        static func nutrientAvatarBackground(for canonicalName: String) -> SwiftUI.Color {
            let n = canonicalName.lowercased()
            if n.contains("vitamin d")  { return SwiftUI.Color(hue: 0.13, saturation: 0.85, brightness: 0.92) }
            if n.contains("vitamin k")  { return SwiftUI.Color(hue: 0.77, saturation: 0.55, brightness: 0.72) }
            if n.contains("vitamin c")  { return SwiftUI.Color(hue: 0.58, saturation: 0.70, brightness: 0.88) }
            if n.contains("vitamin b12"){ return SwiftUI.Color(hue: 0.62, saturation: 0.65, brightness: 0.82) }
            if n.contains("vitamin b")  { return SwiftUI.Color(hue: 0.07, saturation: 0.80, brightness: 0.88) }
            if n.contains("vitamin a")  { return SwiftUI.Color(hue: 0.03, saturation: 0.85, brightness: 0.85) }
            if n.contains("vitamin e")  { return SwiftUI.Color(hue: 0.36, saturation: 0.50, brightness: 0.68) }
            if n == "magnesium"         { return SwiftUI.Color(hue: 0.47, saturation: 0.60, brightness: 0.72) }
            if n == "zinc"              { return SwiftUI.Color(hue: 0.41, saturation: 0.55, brightness: 0.42) }
            if n == "iron"              { return SwiftUI.Color(hue: 0.03, saturation: 0.75, brightness: 0.65) }
            if n == "calcium"           { return SwiftUI.Color(hue: 0.60, saturation: 0.30, brightness: 0.78) }
            if n.contains("omega") || n.contains("dha") || n.contains("epa") {
                return SwiftUI.Color(hue: 0.57, saturation: 0.75, brightness: 0.80)
            }
            if n.contains("selenium")   { return SwiftUI.Color(hue: 0.83, saturation: 0.50, brightness: 0.70) }
            if n.contains("iodine")     { return SwiftUI.Color(hue: 0.68, saturation: 0.55, brightness: 0.75) }
            if n.contains("folate") || n.contains("folic") {
                return SwiftUI.Color(hue: 0.30, saturation: 0.55, brightness: 0.72)
            }
            return SwiftUI.Color(.systemIndigo)
        }

        // MARK: Nutrient abbreviations for circular avatars

        static func nutrientAbbreviation(for canonicalName: String) -> String {
            let n = canonicalName.lowercased()
            if n.contains("vitamin d3") || n.contains("cholecalciferol") { return "D3" }
            if n.contains("vitamin d2") || n.contains("ergocalciferol")  { return "D2" }
            if n.contains("vitamin d")   { return "D"   }
            if n.contains("vitamin k2")  { return "K2"  }
            if n.contains("vitamin k1")  { return "K1"  }
            if n.contains("vitamin k")   { return "K"   }
            if n.contains("vitamin c")   { return "C"   }
            if n.contains("vitamin b12") { return "B12" }
            if n.contains("vitamin b6")  { return "B6"  }
            if n.contains("vitamin b3") || n.contains("niacin") { return "B3" }
            if n.contains("vitamin b2") || n.contains("riboflavin") { return "B2" }
            if n.contains("vitamin b1") || n.contains("thiamin")    { return "B1" }
            if n.contains("biotin")      { return "B7"  }
            if n.contains("folate") || n.contains("folic") { return "B9" }
            if n.contains("vitamin b")   { return "B"   }
            if n.contains("vitamin a")   { return "A"   }
            if n.contains("vitamin e")   { return "E"   }
            if n == "magnesium"          { return "Mg"  }
            if n == "zinc"               { return "Zn"  }
            if n == "iron"               { return "Fe"  }
            if n == "calcium"            { return "Ca"  }
            if n.contains("selenium")    { return "Se"  }
            if n.contains("iodine")      { return "I"   }
            if n.contains("omega")       { return "Ω3"  }
            if n.contains("dha")         { return "DHA" }
            if n.contains("epa")         { return "EPA" }
            if n.contains("taurine")     { return "Tau" }
            if n.contains("coenzyme") || n.contains("coq10") { return "Q10" }
            // Fallback: up to 3 chars of first word, uppercased
            let first = canonicalName.components(separatedBy: " ").first ?? canonicalName
            return String(first.prefix(3)).uppercased()
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 12
        static let l:   CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner radii

    enum Radius {
        static let card:   CGFloat = 16
        static let chip:   CGFloat = 20
        static let avatar: CGFloat = .infinity  // circle
    }
}
