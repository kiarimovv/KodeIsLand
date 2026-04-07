//
//  TerminalAppRegistry.swift
//  ClaudeIsland
//
//  Centralized registry of known terminal applications
//

import Foundation

/// Registry of known terminal application names and bundle identifiers
struct TerminalAppRegistry: Sendable {
    /// Terminal app names for process matching
    static let appNames: Set<String> = [
        "Terminal",
        "iTerm2",
        "iTerm",
        "Ghostty",
        "Alacritty",
        "kitty",
        "Hyper",
        "Warp",
        "WezTerm",
        "Tabby",
        "Rio",
        "Contour",
        "foot",
        "st",
        "urxvt",
        "xterm",
        "cmux",
        "Code",           // VS Code
        "Code - Insiders",
        "Cursor",
        "Windsurf",
        "zed"
    ]

    /// Bundle identifiers for terminal apps (for window enumeration)
    static let bundleIdentifiers: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "io.alacritty",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm",
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.todesktop.230313mzl4w4u92",  // Cursor
        "com.exafunction.windsurf",
        "dev.zed.Zed",
        "com.cmuxterm.app"
    ]

    /// Map a process command name to a friendly display name
    static func displayName(for command: String) -> String {
        let basename = URL(fileURLWithPath: command).lastPathComponent.lowercased()

        let exactMappings: [String: String] = [
            "code": "VS Code",
            "code - insiders": "VS Code",
            "st": "st",
            "zed": "Zed",
            "rio": "Rio",
        ]

        if let name = exactMappings[basename] {
            return name
        }

        let containsMappings: [(match: String, name: String)] = [
            ("ghostty", "Ghostty"),
            ("warp", "Warp"),
            ("stable", "Warp"),      // Warp's binary is called "stable"
            ("iterm", "iTerm2"),
            ("terminal", "Terminal"),
            ("alacritty", "Alacritty"),
            ("kitty", "Kitty"),
            ("wezterm", "WezTerm"),
            ("hyper", "Hyper"),
            ("tabby", "Tabby"),
            ("cmux", "cmux"),
            ("cursor", "Cursor"),
            ("windsurf", "Windsurf"),
            ("tmux", "tmux"),
        ]

        for (match, name) in containsMappings {
            if basename.contains(match) { return name }
        }

        return command // fallback to raw command name
    }

    /// Check if an app name or command path is a known terminal
    static func isTerminal(_ appNameOrCommand: String) -> Bool {
        let basename = URL(fileURLWithPath: appNameOrCommand).lastPathComponent.lowercased()

        if appNames.contains(where: { $0.lowercased() == basename }) {
            return true
        }

        let containsPatterns = [
            "ghostty",
            "warp",
            "stable",
            "iterm",
            "terminal",
            "alacritty",
            "kitty",
            "wezterm",
            "hyper",
            "tabby",
            "cmux",
            "cursor",
            "windsurf",
            "tmux",
        ]

        return containsPatterns.contains(where: { basename.contains($0) })
    }

    /// Check if a bundle identifier is a known terminal
    static func isTerminalBundle(_ bundleId: String) -> Bool {
        bundleIdentifiers.contains(bundleId)
    }
}
