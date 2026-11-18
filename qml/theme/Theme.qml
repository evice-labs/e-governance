import QtQuick

QtObject {
    id: theme

    // ── Surfaces & Backgrounds ────────────────────────────────
    // Aligned with Logos Design System
    readonly property color bgCanvas: "#171717"          // Matches Theme.palette.background (gray900)
    readonly property color bgSurface: "#262626"         // Matches Theme.palette.backgroundSecondary (gray850)
    readonly property color bgSurfaceElevated: "#2F2F2F" // Matches Theme.palette.backgroundButton (gray340)
    readonly property color bgSurfaceSubtle: "#343434"   // Matches Theme.palette.surface (gray320)
    readonly property color bgInsetTrough: "#141414"     // Matches Theme.palette.backgroundInset (gray925)
    readonly property color bgGlassOverlay: Qt.rgba(0.09, 0.09, 0.09, 0.85)

    // ── Borders, Bevels & Lighting ────────────────────────────
    readonly property color borderSubtle: "#333333"       // Matches Theme.palette.borderSubtle (gray330)
    readonly property color borderCard: "#3D3D3D"         // Matches Theme.palette.border (gray300 / gray330)
    readonly property color borderActive: "#0A70F5"
    readonly property color bevelHighlightTop: Qt.rgba(1.0, 1.0, 1.0, 0.16)
    readonly property color bevelHighlightSubtle: Qt.rgba(1.0, 1.0, 1.0, 0.08)
    readonly property color innerShadowDark: Qt.rgba(0.0, 0.0, 0.0, 0.55)
    readonly property color shadowDropDark: Qt.rgba(0.0, 0.0, 0.0, 0.40)

    // ── Primary Tactile Blue Button ───────────────────────────
    readonly property color btnPrimaryTop: "#0E76FA"
    readonly property color btnPrimaryBottom: "#0052CC"
    readonly property color btnPrimaryHoverTop: "#1E82FF"
    readonly property color btnPrimaryHoverBottom: "#0A5CD6"
    readonly property color btnPrimaryPressed: "#0040A3"
    readonly property color btnPrimaryBorderTop: Qt.rgba(1.0, 1.0, 1.0, 0.40)
    readonly property color btnPrimaryBorderSides: "#0B60DE"
    readonly property color btnPrimaryShadow: Qt.rgba(0.04, 0.44, 0.96, 0.35)

    // ── Secondary Tactile Charcoal Button ─────────────────────
    readonly property color btnSecondaryTop: "#363636"
    readonly property color btnSecondaryBottom: "#2A2A2A"
    readonly property color btnSecondaryHoverTop: "#424242"
    readonly property color btnSecondaryHoverBottom: "#323232"
    readonly property color btnSecondaryPressed: "#222222"
    readonly property color btnSecondaryBorderTop: Qt.rgba(1.0, 1.0, 1.0, 0.18)
    readonly property color btnSecondaryBorderSides: "#434343"
    readonly property color btnSecondaryShadow: Qt.rgba(0.0, 0.0, 0.0, 0.35)

    // ── Accent & Semantic Status Colors ───────────────────────
    readonly property color accentOrange: "#FF8438"
    readonly property color accentCyan: "#00E5FF"
    readonly property color statusSuccess: "#00E575"
    readonly property color statusWarning: "#EAB308"
    readonly property color statusDanger: "#EF4444"
    readonly property color statusShielded: "#A855F7"
    readonly property color statusPublic: "#0A70F5"

    // ── Typography ────────────────────────────────────────────
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A4A4A4"    // Matches Theme.palette.textSecondary (gray400)
    readonly property color textMuted: "#717784"        // Matches Theme.palette.textPlaceholder (gray600)
    readonly property color textDisabled: "#5C5C5C"     // Matches Theme.palette.textMuted (gray700)

    readonly property string fontFamily: "Inter, -apple-system, Roboto, sans-serif"
    readonly property string fontMono: "JetBrains Mono, SF Mono, Menlo, monospace"

    // ── Typography Scale ──────────────────────────────────────
    readonly property int titleText: 30        // Theme.typography.titleText
    readonly property int panelTitleText: 24   // Theme.typography.panelTitleText (Judul)
    readonly property int subtitleText: 16     // Theme.typography.subtitleText (Subtitle)
    readonly property int primaryText: 14      // Theme.typography.primaryText (Body)
    readonly property int secondaryText: 12    // Theme.typography.secondaryText (Description)
    readonly property int badgeText: 10        // Theme.typography.badgeText (Tiny)

    // Font weights
    readonly property int weightRegular: 400
    readonly property int weightMedium: 500
    readonly property int weightBold: 700

    // Aliases
    readonly property int fontSizeHero: 28
    readonly property int fontSizeTitle: panelTitleText    // 24
    readonly property int fontSizeSubtitle: subtitleText   // 16
    readonly property int fontSizeBody: primaryText        // 14
    readonly property int fontSizeSmall: secondaryText     // 12
    readonly property int fontSizeTiny: badgeText          // 10

    // ── Spacing Scale ─────────────────────────────────────────
    readonly property int spacingTiny: 4      // Theme.spacing.tiny
    readonly property int spacingSmall: 8     // Theme.spacing.small
    readonly property int spacingMedium: 12   // Theme.spacing.medium
    readonly property int spacingLarge: 16    // Theme.spacing.large
    readonly property int spacingXlarge: 20   // Theme.spacing.xlarge
    readonly property int spacingXxlarge: 40  // Theme.spacing.xxlarge

    // ── Metrics & Geometry ────────────────────────────────────
    readonly property int radiusTiny: 2
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 6
    readonly property int radiusLarge: 8
    readonly property int radiusPill: 999
    readonly property int radiusButton: 6
    readonly property int radiusCard: 8
    readonly property int radiusInset: 6
    readonly property int radiusProgress: 4
}
