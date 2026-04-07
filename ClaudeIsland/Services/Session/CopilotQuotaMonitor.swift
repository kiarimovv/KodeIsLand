//
//  CopilotQuotaMonitor.swift
//  ClaudeIsland
//
//  Monitors GitHub Copilot quota for OpenCode sessions.
//  Reads the GitHub token from ~/.local/share/opencode/auth.json
//  and queries the GitHub API for Copilot subscription/usage info.
//

import Combine
import Foundation
import SwiftUI

/// Copilot quota display info
struct CopilotQuotaInfo: Equatable {
    /// e.g. "copilot_pro", "copilot_enterprise", "copilot_free"
    let planName: String?
    /// Premium requests used this billing period (nil if not available for the plan)
    let premiumUsed: Int?
    /// Premium requests included in plan (nil if unlimited)
    let premiumLimit: Int?
    /// Next billing / reset date
    let nextResetAt: Date?

    var displayText: String {
        guard let used = premiumUsed, let limit = premiumLimit, limit > 0 else {
            return planName.map { shortPlan($0) } ?? "Copilot"
        }
        let pct = Int(Double(used) / Double(limit) * 100)
        let resetStr = nextResetAt.map { formatRemaining($0) } ?? ""
        return "\(pct)%\(resetStr.isEmpty ? "" : " \(resetStr)")"
    }

    var tooltip: String {
        var lines: [String] = []
        if let plan = planName { lines.append("Plan: \(shortPlan(plan))") }
        if let used = premiumUsed, let limit = premiumLimit {
            lines.append("Premium requests: \(used)/\(limit)")
        }
        if let reset = nextResetAt {
            lines.append("重置: \(formatRemainingLong(reset))后")
        }
        return lines.isEmpty ? "Copilot 用量" : lines.joined(separator: "\n")
    }

    var color: Color {
        guard let used = premiumUsed, let limit = premiumLimit, limit > 0 else {
            return Color(red: 0.29, green: 0.87, blue: 0.5)
        }
        let pct = Int(Double(used) / Double(limit) * 100)
        if pct >= 90 { return Color(red: 0.94, green: 0.27, blue: 0.27) }
        if pct >= 70 { return Color(red: 1.0, green: 0.6, blue: 0.2) }
        return Color(red: 0.29, green: 0.87, blue: 0.5)
    }

    private func shortPlan(_ plan: String) -> String {
        switch plan {
        case "copilot_pro_plus", "individual_pro_plus": return "Pro+"
        case "copilot_pro", "individual_pro": return "Pro"
        case "copilot_enterprise", "individual_enterprise": return "Enterprise"
        case "copilot_free", "individual_free": return "Free"
        case "copilot_active": return "Active"
        default:
            // Strip known prefixes, then capitalize
            let stripped = plan
                .replacingOccurrences(of: "copilot_", with: "")
                .replacingOccurrences(of: "individual_", with: "")
            return stripped.isEmpty ? plan : stripped.capitalized
        }
    }

    private func formatRemaining(_ date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return "" }
        if remaining < 3600 { return "\(Int(remaining / 60))m" }
        if remaining < 86400 {
            let h = Int(remaining / 3600)
            let m = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
            return m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }
        return "\(Int(remaining / 86400))d"
    }

    private func formatRemainingLong(_ date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return "" }
        if remaining < 3600 { return "\(Int(remaining / 60))分钟" }
        if remaining < 86400 {
            let h = Int(remaining / 3600)
            let m = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
            return m > 0 ? "\(h)小时\(m)分钟" : "\(h)小时"
        }
        return "\(Int(remaining / 86400))天"
    }
}

@MainActor
class CopilotQuotaMonitor: ObservableObject {
    static let shared = CopilotQuotaMonitor()

    @Published private(set) var quotaInfo: CopilotQuotaInfo?
    @Published private(set) var isLoading = false

    private var refreshTimer: Timer?

    private enum DebugLogger {
        static func log(_ category: String, _ message: String) {
            Swift.print("[\(category)] \(message)")
        }
    }

    private init() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        Task { await refresh() }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        quotaInfo = await fetchQuota()
    }

    // MARK: - Auth

    /// Read GitHub token from ~/.local/share/opencode/auth.json
    /// OpenCode stores provider tokens in this file.
    private func readGitHubToken() -> String? {
        let authPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/opencode/auth.json")

        guard let data = try? Data(contentsOf: authPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DebugLogger.log("Copilot", "Cannot read auth.json")
            return nil
        }

        // Try known key variants for the GitHub Copilot provider
        // opencode stores as "github-copilot" with token in "access" field
        let providerKeys = ["github-copilot", "github_copilot", "copilot", "github", "githubcopilot"]
        for key in providerKeys {
            guard let providerData = json[key] as? [String: Any] else { continue }
            // Try common token field names (opencode uses "access")
            for tokenKey in ["access", "access_token", "token", "github_token", "accessToken", "refresh"] {
                if let token = providerData[tokenKey] as? String, !token.isEmpty {
                    DebugLogger.log("Copilot", "Token found under \(key).\(tokenKey)")
                    return token
                }
            }
        }

        DebugLogger.log("Copilot", "No Copilot token found in auth.json (keys: \(json.keys.joined(separator: ",")))")
        return nil
    }

    // MARK: - Quota Fetch

    private func fetchQuota() async -> CopilotQuotaInfo? {
        guard let token = readGitHubToken() else { return nil }

        // Step 1: fetch Copilot subscription info
        async let subscription = fetchCopilotSubscription(token: token)
        async let copilotToken = fetchCopilotToken(token: token)

        let (sub, tokenInfo) = await (subscription, copilotToken)
        guard sub != nil || tokenInfo != nil else { return nil }

        let remainingPct = sub?.primaryPercentageRemaining
            ?? tokenInfo?.limitedUserQuotas.flatMap { extractMinPercentageRemaining(from: $0) }

        let premiumUsed: Int?
        let premiumLimit: Int?
        if let remainingPct {
            let normalized = max(0.0, min(100.0, remainingPct))
            premiumUsed = Int((100.0 - normalized).rounded())
            premiumLimit = 100
        } else {
            premiumUsed = nil
            premiumLimit = nil
        }

        let nextResetAt = sub?.nextBillingDate ?? tokenInfo?.limitedUserResetDate

        return CopilotQuotaInfo(
            planName: sub?.planType ?? tokenInfo?.sku,
            premiumUsed: premiumUsed,
            premiumLimit: premiumLimit,
            nextResetAt: nextResetAt
        )
    }

    // MARK: - GitHub API Calls

    private struct CopilotSubscription {
        let planType: String
        let nextBillingDate: Date?
        let quotaSnapshots: [String: Any]?
        let primaryPercentageRemaining: Double?
    }

    private struct CopilotTokenInfo {
        let sku: String?
        let limitedUserQuotas: [String: Any]?
        let limitedUserResetDate: Date?
    }

    /// GET https://api.github.com/copilot_internal/user
    /// Returns Copilot plan info for the authenticated user.
    private func fetchCopilotSubscription(token: String) async -> CopilotSubscription? {
        guard let url = URL(string: "https://api.github.com/copilot_internal/user") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2025-04-01", forHTTPHeaderField: "X-GitHub-Api-Version")
        req.timeoutInterval = 10

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DebugLogger.log("Copilot", "copilot_internal/user: \((resp as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }
            let planType = json["copilot_plan"] as? String
                ?? (json["public_key"] != nil ? "copilot_active" : nil)
            // API returns either next_billing_date or quota_reset_date (individual plans)
            let dateStr = json["next_billing_date"] as? String
                ?? json["quota_reset_date"] as? String
            let quotaSnapshots = json["quota_snapshots"] as? [String: Any]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let nextBilling = dateStr.flatMap { formatter.date(from: $0) }
            let primaryPercentageRemaining = quotaSnapshots.flatMap { extractMinPercentageRemaining(from: $0) }
            DebugLogger.log(
                "Copilot",
                "copilot_internal/user success plan=\(planType ?? "unknown") resetDate=\(dateStr ?? "nil") hasSnapshots=\(quotaSnapshots != nil) primaryRemaining=\(primaryPercentageRemaining.map { String(format: "%.2f", $0) } ?? "nil")"
            )
            return CopilotSubscription(
                planType: planType ?? "copilot_active",
                nextBillingDate: nextBilling,
                quotaSnapshots: quotaSnapshots,
                primaryPercentageRemaining: primaryPercentageRemaining
            )
        } catch {
            DebugLogger.log("Copilot", "Subscription fetch error: \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchCopilotToken(token: String) async -> CopilotTokenInfo? {
        guard let url = URL(string: "https://api.github.com/copilot_internal/v2/token") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("2025-04-01", forHTTPHeaderField: "X-GitHub-Api-Version")
        req.setValue("CodeIsland", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DebugLogger.log("Copilot", "copilot_internal/v2/token failed status=\(statusCode)")
                return nil
            }

            let topLevelSku = json["sku"] as? String
            let topLevelLimitedUserQuotas = json["limited_user_quotas"] as? [String: Any]
            let topLevelLimitedUserResetDate = (json["limited_user_reset_date"] as? TimeInterval)
                .map { Date(timeIntervalSince1970: $0) }

            let jwt = json["token"] as? String
            let payload = jwt.flatMap(decodeJWTPayload)

            let payloadSku = payload?["sku"] as? String
            let payloadLimitedUserQuotas = payload?["limited_user_quotas"] as? [String: Any]
            let payloadLimitedUserResetDate = (payload?["limited_user_reset_date"] as? TimeInterval)
                .map { Date(timeIntervalSince1970: $0) }

            let derivedPayloadQuota = payload.flatMap { extractQuotaLikeDictionary(from: $0) }

            let limitedUserQuotas = topLevelLimitedUserQuotas
                ?? payloadLimitedUserQuotas
                ?? derivedPayloadQuota
            let limitedUserResetDate = topLevelLimitedUserResetDate ?? payloadLimitedUserResetDate
            let sku = topLevelSku ?? payloadSku

            if let payload {
                DebugLogger.log(
                    "Copilot",
                    "jwt payload parsed hasLimitedQuotas=\(payloadLimitedUserQuotas != nil) hasDerivedQuota=\(derivedPayloadQuota != nil) hasResetDate=\(payloadLimitedUserResetDate != nil) hasSku=\(payloadSku != nil)"
                )
            } else {
                DebugLogger.log("Copilot", "jwt payload unavailable")
            }

            DebugLogger.log(
                "Copilot",
                "copilot_internal/v2/token success sku=\(sku ?? "nil") hasLimitedQuotas=\(limitedUserQuotas != nil) resetAt=\(limitedUserResetDate?.description ?? "nil")"
            )
            return CopilotTokenInfo(
                sku: sku,
                limitedUserQuotas: limitedUserQuotas,
                limitedUserResetDate: limitedUserResetDate
            )
        } catch {
            DebugLogger.log("Copilot", "copilot_internal/v2/token error: \(error.localizedDescription)")
            return nil
        }
    }

    private func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count >= 2 else {
            DebugLogger.log("Copilot", "jwt decode failed reason=invalid_segments")
            return nil
        }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let payloadData = Data(base64Encoded: base64) else {
            DebugLogger.log("Copilot", "jwt decode failed reason=base64url_decode")
            return nil
        }

        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            DebugLogger.log("Copilot", "jwt decode failed reason=payload_json_parse")
            return nil
        }

        DebugLogger.log("Copilot", "jwt decode success keys=\(payload.keys.count)")
        return payload
    }

    private func extractQuotaLikeDictionary(from payload: [String: Any]) -> [String: Any]? {
        let preferredKeys = ["chat", "completions"]
        for key in preferredKeys {
            guard let candidate = payload[key] else { continue }
            if let dictionary = candidate as? [String: Any], hasQuotaSignal(in: dictionary) {
                DebugLogger.log("Copilot", "jwt quota candidate source=\(key)")
                return [key: dictionary]
            }
            if let array = candidate as? [Any], hasQuotaSignal(in: array) {
                DebugLogger.log("Copilot", "jwt quota candidate source=\(key)_array")
                return [key: array]
            }
        }

        for (key, value) in payload {
            if let dictionary = value as? [String: Any], hasQuotaSignal(in: dictionary) {
                DebugLogger.log("Copilot", "jwt quota candidate source=\(key)")
                return [key: dictionary]
            }
            if let array = value as? [Any], hasQuotaSignal(in: array) {
                DebugLogger.log("Copilot", "jwt quota candidate source=\(key)_array")
                return [key: array]
            }
        }
        return nil
    }

    private func hasQuotaSignal(in payload: Any) -> Bool {
        if let dictionary = payload as? [String: Any] {
            let normalizedKeys = dictionary.keys.map { $0.lowercased() }
            if normalizedKeys.contains(where: {
                $0.contains("percent") || $0.contains("remaining") || $0.contains("quota") || $0.contains("limit") || $0.contains("total") || $0.contains("max") || $0.contains("entitlement")
            }) {
                return true
            }
            for value in dictionary.values where hasQuotaSignal(in: value) {
                return true
            }
            return false
        }

        if let array = payload as? [Any] {
            for element in array where hasQuotaSignal(in: element) {
                return true
            }
        }
        return false
    }

    private func extractMinPercentageRemaining(from payload: Any) -> Double? {
        var values: [Double] = []
        collectPercentageRemaining(from: payload, into: &values)
        return values.min()
    }

    private func collectPercentageRemaining(from payload: Any, into values: inout [Double]) {
        if let dictionary = payload as? [String: Any] {
            // GitHub API 使用 percent_remaining（无 "age" 后缀），部分版本可能用 percentage_remaining
            if let raw = toDouble(dictionary["percent_remaining"])
                ?? toDouble(dictionary["percentage_remaining"]) {
                // 跳过 unlimited 类目（remaining==100 且无实际配额限制）
                let isUnlimited = (dictionary["unlimited"] as? Bool) == true
                if !isUnlimited {
                    values.append(raw)
                }
            } else if let remaining = toDouble(dictionary["remaining"]),
                      let total = toDouble(dictionary["entitlement"])
                        ?? toDouble(dictionary["quota"])
                        ?? toDouble(dictionary["limit"])
                        ?? toDouble(dictionary["total"])
                        ?? toDouble(dictionary["max"]),
                      total > 0 {
                values.append((remaining / total) * 100.0)
            }

            for value in dictionary.values {
                collectPercentageRemaining(from: value, into: &values)
            }
            return
        }

        if let array = payload as? [Any] {
            for element in array {
                collectPercentageRemaining(from: element, into: &values)
            }
        }
    }

    private func toDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }
}
