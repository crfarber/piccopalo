import SwiftUI

struct Theme {
    // MARK: - Colors (Palette)
    struct Colors {
        // Surfaces
        static let background = Color(red: 0.055, green: 0.063, blue: 0.063)  // #0E1010
        static let surface = Color(red: 0.102, green: 0.114, blue: 0.110)  // #1A1D1C
        static let surface2 = Color(red: 0.141, green: 0.157, blue: 0.153)  // #242827

        // Foreground
        static let text = Color(red: 0.949, green: 0.945, blue: 0.925)  // #F2F1EC
        static let textMuted = Color(red: 0.949, green: 0.945, blue: 0.925, opacity: 0.62)
        static let textDim = Color(red: 0.949, green: 0.945, blue: 0.925, opacity: 0.38)

        // Brand accents
        static let cream = Color(red: 0.956, green: 0.894, blue: 0.659)  // #F4E4A8
        static let creamDeep = Color(red: 0.910, green: 0.824, blue: 0.473)  // #E8D279
        static let green = Color(red: 0.608, green: 0.820, blue: 0.455)  // #9BD174
        static let blue = Color(red: 0.267, green: 0.627, blue: 0.933)  // #4400EE (water tracking)
        static let tomato = Color(red: 0.910, green: 0.482, blue: 0.361)  // #E87B5C

        // Jar layers
        static let layerA = Color(red: 0.956, green: 0.894, blue: 0.659)  // egg pasta
        static let layerB = Color(red: 0.910, green: 0.722, blue: 0.447)  // semolina
        static let layerC = Color(red: 0.792, green: 0.478, blue: 0.353)  // tomato sauce
        static let layerD = Color(red: 0.608, green: 0.820, blue: 0.455)  // basil/herb

        // Feedback
        static let success = Color(red: 0.608, green: 0.820, blue: 0.455)  // #9BD174
        static let error = Color(red: 0.910, green: 0.482, blue: 0.361)  // #E87B5C
        static let warning = Color(red: 0.910, green: 0.824, blue: 0.473)  // #E8D279
        static let info = Color(red: 0.792, green: 0.478, blue: 0.353)  // #C77A5B

        // Additional colors
        static let accent = Color(red: 0.608, green: 0.820, blue: 0.455)  // #9BD174
    }

    struct Typography {
        static let displayFont = "Instrument Serif"
        static let uiFont = ".SF Pro Text"
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    struct Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let pill: CGFloat = 999
    }
}
