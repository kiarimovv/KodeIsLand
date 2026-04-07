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

    /// sessionId → (dbModTime, messages) — 完整对话缓存
    private var fullCache: [String: (modTime: TimeInterval, messages: [ChatMessage])] = [:]

    // MARK: - Public

    func parseFullConversation(sessionId: String) -> [ChatMessage] {
        let modTime = dbModificationTime()
        if let hit = fullCache[sessionId], hit.modTime == modTime {
            return hit.messages
        }
        let messages = queryFullConversation(sessionId: sessionId)
        fullCache[sessionId] = (modTime: modTime, messages: messages)
        return messages
    }

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

    /// 查询完整对话：message + part，按时间排序后组装为 [ChatMessage]
    private func queryFullConversation(sessionId: String) -> [ChatMessage] {
        let sql = """
        SELECT m.id AS message_id,
               json_extract(m.data,'$.role') AS role,
               m.time_created AS msg_ts,
               p.id AS part_id,
               json_extract(p.data,'$.type') AS part_type,
               json_extract(p.data,'$.text') AS text,
               json_extract(p.data,'$.tool') AS tool_name,
               p.data AS part_data,
               p.time_created AS part_ts
        FROM message m
        JOIN part p ON p.message_id = m.id
        WHERE m.session_id = '\(esc(sessionId))'
          AND (json_extract(p.data,'$.type') != 'text'
               OR json_extract(p.data,'$.text') NOT LIKE '%INTERNAL%')
        ORDER BY m.time_created ASC, p.time_created ASC;
        """

        guard let rows = runSQL(sql) else { return [] }

        var grouped: [(id: String, role: String, ts: Int64, parts: [[String: Any]])] = []
        var indexMap: [String: Int] = [:]

        for row in rows {
            guard let msgId = row["message_id"] as? String,
                  let role = row["role"] as? String else { continue }

            let ts: Int64
            if let v = row["msg_ts"] as? Int64 { ts = v }
            else if let v = row["msg_ts"] as? Double { ts = Int64(v) }
            else if let s = row["msg_ts"] as? String, let v = Int64(s) { ts = v }
            else { ts = 0 }

            if let idx = indexMap[msgId] {
                grouped[idx].parts.append(row)
            } else {
                indexMap[msgId] = grouped.count
                grouped.append((id: msgId, role: role, ts: ts, parts: [row]))
            }
        }

        var messages: [ChatMessage] = []
        for group in grouped {
            let chatRole: ChatRole = group.role == "user" ? .user : .assistant
            let timestamp = Date(timeIntervalSince1970: Double(group.ts) / 1000.0)

            var blocks: [MessageBlock] = []
            for part in group.parts {
                guard let partType = part["part_type"] as? String else { continue }

                switch partType {
                case "text":
                    guard let raw = part["text"] as? String,
                          let cleaned = cleanText(raw), !cleaned.isEmpty else { continue }
                    blocks.append(.text(cleaned))

                case "tool":
                    let toolName = (part["tool_name"] as? String) ?? "unknown"
                    let partId = (part["part_id"] as? String) ?? UUID().uuidString
                    let input = extractToolInput(from: part["part_data"])
                    blocks.append(.toolUse(ToolUseBlock(id: partId, name: toolName, input: input)))

                default:
                    // step-start / step-finish 等类型忽略
                    break
                }
            }

            guard !blocks.isEmpty else { continue }
            messages.append(ChatMessage(
                id: group.id,
                role: chatRole,
                timestamp: timestamp,
                content: blocks
            ))
        }

        Self.logger.debug("parseFullConversation sid=\(sessionId.prefix(8)) msgs=\(messages.count, privacy: .public)")
        return messages
    }

    private func extractToolInput(from partData: Any?) -> [String: String] {
        guard let raw = partData as? String,
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        // OpenCode part.data 中可能有 input / arguments 等字段
        if let input = json["input"] as? [String: Any] {
            return input.compactMapValues { "\($0)" }
        }
        if let args = json["arguments"] as? [String: Any] {
            return args.compactMapValues { "\($0)" }
        }
        return [:]
    }

    // MARK: - Run SQL

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
