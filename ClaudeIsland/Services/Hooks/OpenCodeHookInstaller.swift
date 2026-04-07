//
//  OpenCodeHookInstaller.swift
//  ClaudeIsland
//
//  Auto-installs the CodeIsland OpenCode plugin on app launch.
//  OpenCode auto-discovers all .mjs/.js files in ~/.config/opencode/plugins/
//

import Foundation

struct OpenCodeHookInstaller {

    /// Plugin filename inside ~/.config/opencode/plugins/
    private static let pluginFileName = "codeisland-opencode.mjs"

    /// Install plugin on app launch (safe to call every launch — it overwrites to keep updated)
    static func installIfNeeded() {
        let pluginsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/opencode/plugins")

        do {
            try FileManager.default.createDirectory(
                at: pluginsDir,
                withIntermediateDirectories: true
            )
        } catch {
            DebugLogger.log("OpenCode", "Cannot create plugins dir: \(error.localizedDescription)")
            return
        }

        guard let bundled = Bundle.main.url(forResource: "codeisland-opencode", withExtension: "mjs") else {
            DebugLogger.log("OpenCode", "Plugin resource not found in bundle")
            return
        }

        let dest = pluginsDir.appendingPathComponent(pluginFileName)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: bundled, to: dest)
            DebugLogger.log("OpenCode", "Plugin installed at \(dest.path)")
        } catch {
            DebugLogger.log("OpenCode", "Install error: \(error.localizedDescription)")
        }
    }

    /// Remove the plugin file (called from Settings)
    static func uninstall() {
        let dest = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/opencode/plugins/\(pluginFileName)")
        try? FileManager.default.removeItem(at: dest)
        DebugLogger.log("OpenCode", "Plugin removed")
    }

    /// Whether the plugin is currently installed
    static func isInstalled() -> Bool {
        let dest = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/opencode/plugins/\(pluginFileName)")
        return FileManager.default.fileExists(atPath: dest.path)
    }
}
