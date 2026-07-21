import Foundation

/// The themes shipped inside the app bundle. These always work with no network, and the
/// contrast/distinguishability tests in `ThemeContrastTests` gate every value here:
/// text roles hold WCAG AA against their surfaces, and the player palettes stay mutually
/// distinguishable under normal vision and simulated protanopia/deuteranopia.
enum BuiltInThemes {
    static let all: [AppTheme] = [hearth, meadow, tablerules, gaslight, toolbox, contrast]

    static let defaultTheme = hearth

    static func theme(id: String) -> AppTheme? {
        all.first { $0.id == id }
    }

    /// The soft, earthy default: deep blue-green, parchment, clay. Game night under a lamp.
    static let hearth = AppTheme(
        id: "hearth",
        name: "Hearth",
        tags: ["earthy", "soft", "default"],
        light: ThemePalette(
            backgroundHex: "#EDE4D2", surfaceHex: "#F6F0E2", surfaceElevatedHex: "#FCF8EE",
            tableHex: "#2F5D50",
            accentHex: "#A6512E", accentSecondaryHex: "#2F5D50",
            textPrimaryHex: "#26322B", textSecondaryHex: "#57604F",
            positiveHex: "#2E6B4A", negativeHex: "#9C3F35", warningHex: "#8F6A2B",
            diceFaceHex: "#F9F4E7", dicePipHex: "#2B382F",
            playerHexes: ["#2F5B52", "#B85C38", "#46688F", "#77293B", "#C9973B",
                          "#7FA184", "#37818A", "#7B6FAE", "#7A5230", "#BB8FA0"]),
        dark: ThemePalette(
            backgroundHex: "#121A15", surfaceHex: "#1B2620", surfaceElevatedHex: "#243129",
            tableHex: "#24443B",
            accentHex: "#C97B54", accentSecondaryHex: "#8FB49B",
            textPrimaryHex: "#EDE6D6", textSecondaryHex: "#A9B2A6",
            positiveHex: "#86C29A", negativeHex: "#E08D7D", warningHex: "#D9AE63",
            diceFaceHex: "#F3EBDA", dicePipHex: "#2B382F",
            playerHexes: ["#5E9C86", "#DB8D59", "#668CAE", "#B86664", "#E6B46A",
                          "#9BCCC6", "#74C7DD", "#A79BD6", "#B08A62", "#DA95A7"]))

    /// Soft botanical light theme: meadow greens, poppy, cornflower.
    static let meadow = AppTheme(
        id: "meadow",
        name: "Meadow",
        tags: ["nature", "soft", "light"],
        light: ThemePalette(
            backgroundHex: "#EDF1E8", surfaceHex: "#F8FAF3", surfaceElevatedHex: "#FFFFFF",
            tableHex: "#54774F",
            accentHex: "#4E7A42", accentSecondaryHex: "#C25F4A",
            textPrimaryHex: "#2C332B", textSecondaryHex: "#59614F",
            positiveHex: "#41754B", negativeHex: "#A84A3F", warningHex: "#84651F",
            diceFaceHex: "#FDFCF4", dicePipHex: "#3A4234",
            playerHexes: ["#65926B", "#BD6E4F", "#55AAC8", "#9C5F94", "#C3912D",
                          "#40837C", "#8A5A3F", "#3C5977", "#A93E5C", "#8B7FC1"]),
        dark: ThemePalette(
            backgroundHex: "#161B14", surfaceHex: "#202619", surfaceElevatedHex: "#2A3222",
            tableHex: "#37432F",
            accentHex: "#8FBA7F", accentSecondaryHex: "#D98B6A",
            textPrimaryHex: "#EAEBDD", textSecondaryHex: "#A8AF9E",
            positiveHex: "#8FC796", negativeHex: "#DB9080", warningHex: "#D2B266",
            diceFaceHex: "#F0EEDC", dicePipHex: "#333B2D",
            playerHexes: ["#778B53", "#DB8A70", "#D2B8E4", "#9C7EB5", "#D8BA6A",
                          "#31A19E", "#E4AE8F", "#CBB8C0", "#B9768E", "#7CA1D6"]))

    /// Modern rulebook print: paper, ink, flat forest and clay fills.
    static let tablerules = AppTheme(
        id: "tablerules",
        name: "Table Rules",
        tags: ["print", "graphic", "bold"],
        light: ThemePalette(
            backgroundHex: "#F2F1EA", surfaceHex: "#FBFAF4", surfaceElevatedHex: "#FFFFFF",
            tableHex: "#2F5D50",
            accentHex: "#C24C2C", accentSecondaryHex: "#2F5D50",
            textPrimaryHex: "#1D211F", textSecondaryHex: "#555E59",
            positiveHex: "#2C6A47", negativeHex: "#A63A2A", warningHex: "#8A6420",
            diceFaceHex: "#FBFAF4", dicePipHex: "#1D211F",
            playerHexes: ["#2F5D50", "#C24C2C", "#2B5E8C", "#8E354C", "#C99022",
                          "#6B8F3D", "#17777F", "#6A4FA3", "#50432D", "#B98BAE"]),
        dark: ThemePalette(
            backgroundHex: "#121719", surfaceHex: "#1A2124", surfaceElevatedHex: "#232B2F",
            tableHex: "#253238",
            accentHex: "#E68A62", accentSecondaryHex: "#7FB09A",
            textPrimaryHex: "#ECECE4", textSecondaryHex: "#A6ADA9",
            positiveHex: "#7FC796", negativeHex: "#E08D7D", warningHex: "#D9B15C",
            diceFaceHex: "#2F5D50", dicePipHex: "#F4F3ED",
            playerHexes: ["#83BD96", "#C5884B", "#A4ACD6", "#CE7295", "#D9B15C",
                          "#97BB6E", "#A7CED2", "#9E8CC9", "#91895C", "#DF9FB5"]))

    /// The parlor after dark: velvet greens and candle-lit brass. Built for dim rooms.
    static let gaslight = AppTheme(
        id: "gaslight",
        name: "Gaslight",
        tags: ["dark", "elegant", "night"],
        light: ThemePalette(
            backgroundHex: "#EAE6DA", surfaceHex: "#F5F2E8", surfaceElevatedHex: "#FCFAF2",
            tableHex: "#567163",
            accentHex: "#8F6A26", accentSecondaryHex: "#3E5E52",
            textPrimaryHex: "#2A2E28", textSecondaryHex: "#5B5F55",
            positiveHex: "#3F6B4F", negativeHex: "#9A4238", warningHex: "#8A6420",
            diceFaceHex: "#F7F3E6", dicePipHex: "#33392F",
            playerHexes: ["#347353", "#A6653C", "#629CBD", "#824862", "#AF7E37",
                          "#788258", "#496C7E", "#7A6698", "#6B4F3A", "#A87686"]),
        dark: ThemePalette(
            backgroundHex: "#0F1613", surfaceHex: "#18211C", surfaceElevatedHex: "#212D26",
            tableHex: "#22352C",
            accentHex: "#C9A45C", accentSecondaryHex: "#8FA895",
            textPrimaryHex: "#E9E2D0", textSecondaryHex: "#A3AB9C",
            positiveHex: "#8FC2A0", negativeHex: "#D98B76", warningHex: "#D9B366",
            diceFaceHex: "#2E4A3D", dicePipHex: "#E9C87E",
            playerHexes: ["#8A9C87", "#DC8F5D", "#91A5BC", "#BF7696", "#DCC095",
                          "#9DB873", "#89D9D0", "#9899CC", "#B08A62", "#DFA3B2"]))

    /// The bright, saturated look of Game Toolkit 2.0, kept as a theme for those who liked it.
    static let toolbox = AppTheme(
        id: "toolbox",
        name: "Toolbox",
        tags: ["bright", "playful", "classic"],
        light: ThemePalette(
            backgroundHex: "#F2F2F6", surfaceHex: "#FFFFFF", surfaceElevatedHex: "#FFFFFF",
            tableHex: "#2E7D5B",
            accentHex: "#E1580E", accentSecondaryHex: "#2A6FDB",
            textPrimaryHex: "#1C1C1E", textSecondaryHex: "#55555C",
            positiveHex: "#1E7A46", negativeHex: "#C0392B", warningHex: "#8A6400",
            diceFaceHex: "#FFFFFF", dicePipHex: "#1C1C1E",
            playerHexes: ["#2D5BCF", "#E13C4C", "#099A4E", "#DEB413", "#966DDA",
                          "#F97316", "#0FA3A3", "#D30876", "#64748B", "#62AC1F"]),
        dark: ThemePalette(
            backgroundHex: "#0E0E10", surfaceHex: "#1B1B1E", surfaceElevatedHex: "#242428",
            tableHex: "#1E4D39",
            accentHex: "#FF7A33", accentSecondaryHex: "#6EA8FF",
            textPrimaryHex: "#F2F2F5", textSecondaryHex: "#A5A5AC",
            positiveHex: "#4ADE80", negativeHex: "#F87171", warningHex: "#FACC15",
            diceFaceHex: "#F5F5F7", dicePipHex: "#1C1C1E",
            playerHexes: ["#7E97D7", "#F2777C", "#75E1A0", "#D5BD19", "#C79BFF",
                          "#FF9E45", "#39D2E6", "#D98492", "#B9BEC7", "#B5F560"]))

    /// Maximum legibility: pure grounds, ink text, strong saturated markers.
    static let contrast = AppTheme(
        id: "contrast",
        name: "High Contrast",
        tags: ["accessible", "high-contrast"],
        light: ThemePalette(
            backgroundHex: "#FFFFFF", surfaceHex: "#FFFFFF", surfaceElevatedHex: "#F2F2F2",
            tableHex: "#D8D8D8",
            accentHex: "#0A50C0", accentSecondaryHex: "#6A0DAD",
            textPrimaryHex: "#000000", textSecondaryHex: "#3C3C43",
            positiveHex: "#006B3F", negativeHex: "#B00020", warningHex: "#704F00",
            diceFaceHex: "#FFFFFF", dicePipHex: "#000000",
            playerHexes: ["#4260D2", "#B00020", "#006B3F", "#6A0DAD", "#906500",
                          "#C2185B", "#006D77", "#3F5046", "#4E342E", "#626832"]),
        dark: ThemePalette(
            backgroundHex: "#000000", surfaceHex: "#111114", surfaceElevatedHex: "#1D1D21",
            tableHex: "#26262B",
            accentHex: "#6EB2FF", accentSecondaryHex: "#D0A3FF",
            textPrimaryHex: "#FFFFFF", textSecondaryHex: "#C7C7CF",
            positiveHex: "#5EDB8E", negativeHex: "#FF8080", warningHex: "#FFD54D",
            diceFaceHex: "#FFFFFF", dicePipHex: "#000000",
            playerHexes: ["#6EB2FF", "#FF8080", "#79E590", "#F7CC3E", "#AC8CE2",
                          "#F89C3A", "#24DEF7", "#F4AEE5", "#C4C9D1", "#CFE061"]))
}
