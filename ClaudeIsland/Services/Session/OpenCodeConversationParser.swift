//
//  OpenCodeConversationParser.swift
//  ClaudeIsland
//
//  Parses OpenCode conversation data from ~/.local/share/opencode/opencode.db
//
//  Uses the system sqlite3 CLI with -json output to avoid requiring libsqlite3 linkage.
//
//  Schema:
//    session(id, title, directory, time_updated, ...)
//    message(id, session_id, data JSON, time_created, ...)   — data.role = "user"|"assistant"
//    part(id, message_id, session_id, data JSON, time_created, ...)
//      data.type = "text"|"tool"|"step-start"|"step-finish"
//      data.text  — text content (type=text)
//      data.tool  — tool name (type=tool)
//

import Foundation
import os.log

actor OpenCodeConversationParser {
    static let shared = OpenCodeConversationParser()

    private static let logger = Logger(subsystem: "com.codeisland", category: "OpenCodeParser")

    private static let dbPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".local/share/opencode/opencode.db")
        .path

    private static let sqlite3 = "/usr/bin/sqlite3"

    /// sessionId → (dbModTime, info)
    private var cache: [String: (modTime: TimeInterval, info: ConversationInfo)] = [:]

    // MARK: - Public

    func parse(sessionId: String) -> ConversationInfo? {
        let modTime = dbModificationTime()
        if let hit = cache[sessionId], hit.modTime == modTime {
            return hit.info
        }
        guard let info = query(sessionId: sessionId) else { return nil }
        cache[sessionId] = (modTime: modTime, info: info)
        return info
    }

    // MARK: - Query

    private func query(sessionId: String) -> ConversationInfo? {
        // Single SQL that returns all we need in one sqlite3 call
        // Using UNION ALL to avoid multiple processes
        let sql = """
        SELECT 'title'   AS kind, title  AS val, 0 AS ts FROM session WHERE id='\(esc(sessionId))' LIMIT 1;
        SELECT 'user_first' AS kind, json_extract(p.data,'$.text') AS val, p.time_created AS ts
          FROM part p JOIN message m ON m.id=p.message_id
          WHERE p.session_id='\(esc(sessionId))'
            AND json_extract(m.data,'$.role')='user'
            AND json_extract(p.data,'$.type')='text'
          ORDER BY p.time_created ASC LIMIT 1;
        SELECT 'user_last' AS kind, json_extract(p.data,'$.text') AS val, p.time_created AS ts
          FROM part p JOIN message m ON m.id=p.message_id
          WHERE p.session_id='\(esc(sessionId))'
            AND json_extract(m.data,'$.role')='user'
            AND json_extract(p.data,'$.type')='text'
          ORDER BY p.time_created DESC LIMIT 1;
        SELECT 'asst_last' AS kind, json_extract(p.data,'$.text') AS val, p.time_created AS ts
          FROM part p JOIN message m ON m.id=p.message_id
          WHERE p.session_id='\(esc(sessionId))'
            AND json_extract(m.data,'$.role')='assistant'
            AND json_extract(p.data,'$.type')='text'
            AND json_extract(p.data,'$.text') NOT LIKE '%INTERNAL%'
          ORDER BY p.time_created DESC LIMIT 1;
        SELECT 'tool_last' AS kind, json_extract(data,'$.tool') AS val, time_created AS ts
          FROM part
          WHERE session_id='\(esc(sessionId))'
            AND json_extract(data,'$.type')='tool'
          ORDER BY time_created DESC LIMIT 1;
        SELECT 'user_date' AS kind, CAST(m.time_created AS TEXT) AS val, m.time_created AS ts
          FROM message m
          WHERE m.session_id='\(esc(sessionId))'
            AND json_extract(m.data,'$.role')='user'
          ORDER BY m.time_created DESC LIMIT 1;
        """

        guard let rows = runSQL(sql) else { return nil }

        var title: String?
        var userFirst: String?
        var userLast: String?
        var asstLast: String?
        var toolLast: String?
        var userDate: Date?

        for row in rows {
            guard let kind = row["kind"] as? String,
                  let val  = row["val"]  as? String,
                  !val.isEmpty else { continue }

            switch kind {
            case "title":
                if val != "New Session" { title = val }
            case "user_first":
                userFirst = cleanText(val)
            case "user_last":
                userLast = cleanText(val)
            case "asst_last":
                asstLast = cleanText(val)
            case "tool_last":
                toolLast = val
            case "user_date":
                if let ms = Int64(val), ms > 0 {
                    userDate = Date(timeIntervalSince1970: Double(ms) / 1000.0)
                }
            default: break
            }
        }

        guard title != nil || userFirst != nil else { return nil }

        return ConversationInfo(
            summary: title,
            lastMessage: asstLast,
            lastMessageRole: asstLast != nil ? "assistant" : nil,
            lastToolName: toolLast,
            firstUserMessage: userFirst,
            latestUserMessage: userLast,
            lastUserMessageDate: userDate
        )
    }

    // MARK: - sqlite3 subprocess

    /// Run one or more SQL statements via sqlite3 -json and return parsed rows.
    private func runSQL(_ sql: String) -> [[String: Any]]? {
        guard FileManager.default.fileExists(atPath: Self.dbPath) else {
            Self.logger.debug("opencode.db not found at \(Self.dbPath, privacy: .public)")
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.sqlite3)
        // -readonly: never write to the DB
        // -json: output as JSON array
        process.arguments = ["-readonly", "-json", Self.dbPath, sql]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError  = errPipe

        do {
            try process.run()
        } catch {
            Self.logger.debug("sqlite3 launch failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 || process.terminationStatus == 1,
              !outData.isEmpty else { return nil }

        // sqlite3 -json outputs one JSON array per statement, each on its own line.
        // e.g.: [{"kind":"title",...}]\n[{"kind":"user_first",...}]\n...
        // Wrap all arrays into a single top-level array and flatten.
        guard var str = String(data: outData, encoding: .utf8) else { return nil }
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace array boundaries "][" (with optional whitespace/newlines) with ","
        // so we get one flat JSON array: [row1, row2, row3, ...]
        let merged = "[" + str
            .replacingOccurrences(of: "\\]\\s*\\[", with: ",", options: .regularExpression)
            .dropFirst()  // remove leading "["
        guard let mergedData = merged.data(using: .utf8),
              let rows = try? JSONSerialization.jsonObject(with: mergedData) as? [[String: Any]] else {
            return nil
        }
        return rows
    }

    // MARK: - Helpers

    /// Escape single quotes for inline SQL (session IDs are random alphanumeric, this is safe)
    private func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "'", with: "''")
    }

    private func cleanText(_ raw: String) -> String? {
        var s = raw
        // Strip OMO_INTERNAL_INITIATOR injections
        if let r = s.range(of: "<!-- OMO_INTERNAL_INITIATOR -->") { s = String(s[s.startIndex..<r.lowerBound]) }
        // Strip system reminders
        if let r = s.range(of: "<system-reminder>") { s = String(s[s.startIndex..<r.lowerBound]) }
        // Truncate pasted content
        if let r = s.range(of: "[Pasted ~") { s = String(s[s.startIndex..<r.lowerBound]) }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    private func dbModificationTime() -> TimeInterval {
        let attrs = try? FileManager.default.attributesOfItem(atPath: Self.dbPath)
        return (attrs?[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? 0
    }
}
