/**
 * CodeIsland OpenCode Plugin
 * Sends session state to CodeIsland.app via Unix socket (/tmp/codeisland.sock)
 * For permission.asked: blocks and waits for user decision, then returns allow/deny
 *
 * Install: copy to ~/.config/opencode/plugins/codeisland-opencode.mjs
 * OpenCode auto-discovers all .mjs/.js files in that directory.
 */
import net from "node:net";

const SOCKET_PATH = "/tmp/codeisland.sock";
const TIMEOUT_MS = 300_000; // 5 minutes (same as Python hook)
const PPID = process.ppid;

/** Send event JSON to CodeIsland socket. Returns parsed response for permission events, null otherwise. */
function sendEvent(state) {
  return new Promise((resolve) => {
    const client = net.createConnection({ path: SOCKET_PATH });
    const isPermission = state.status === "waiting_for_approval";

    let settled = false;
    const settle = (value) => {
      if (!settled) {
        settled = true;
        resolve(value);
      }
    };

    client.setTimeout(TIMEOUT_MS);

    client.on("connect", () => {
      client.write(JSON.stringify(state));
      if (!isPermission) {
        client.end();
        settle(null);
        return;
      }
      // Permission: keep socket open, wait for {"decision":"allow|deny|ask","reason":"..."}
      let data = "";
      client.on("data", (chunk) => { data += chunk.toString(); });
      client.on("end", () => {
        try { settle(JSON.parse(data)); } catch { settle(null); }
      });
    });

    client.on("error", () => settle(null));
    client.on("timeout", () => { client.destroy(); settle(null); });
  });
}

export const CodeIslandPlugin = async ({ project }) => {
  const cwd = project?.path ?? process.cwd();
  // TERM_PROGRAM is set by the terminal that launched this shell (e.g. "ghostty", "vscode", "iTerm.app").
  // More reliable than PID-based process-tree detection for opencode daemon processes.
  const termProgram = process.env.TERM_PROGRAM ?? process.env.TERM ?? "";

  return {
    // ── Session lifecycle ──────────────────────────────────────────────────

    "session.created": async ({ sessionID }) => {
      await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "SessionStart", status: "waiting_for_input",
        source: "opencode",
      });
    },

    "session.deleted": async ({ sessionID }) => {
      await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "SessionEnd", status: "ended",
        source: "opencode",
      });
    },

    "session.idle": async ({ sessionID }) => {
      await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "Notification", status: "waiting_for_input",
        notification_type: "idle_prompt", source: "opencode",
      });
    },

    // ── Tool execution ─────────────────────────────────────────────────────

    "tool.execute.before": async ({ sessionID, toolCallID, tool, input }) => {
      await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "PreToolUse", status: "running_tool",
        tool: tool?.name ?? String(tool ?? ""),
        tool_input: input ?? {},
        tool_use_id: toolCallID,
        source: "opencode",
      });
    },

    "tool.execute.after": async ({ sessionID, toolCallID, tool }) => {
      await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "PostToolUse", status: "processing",
        tool: tool?.name ?? String(tool ?? ""),
        tool_use_id: toolCallID,
        source: "opencode",
      });
    },

    // ── Permission gate ────────────────────────────────────────────────────
    // This handler blocks until CodeIsland responds (or times out).
    // output.set({ granted: true/false }) controls whether the tool runs.

    "permission.asked": async ({ sessionID, toolCallID, tool, input }, output) => {
      const response = await sendEvent({
        session_id: sessionID, cwd,
        pid: process.pid, ppid: PPID, term_program: termProgram,
        event: "PermissionRequest", status: "waiting_for_approval",
        tool: tool?.name ?? String(tool ?? ""),
        tool_input: input ?? {},
        tool_use_id: toolCallID,
        source: "opencode",
      });

      if (response?.decision === "allow") {
        output?.set?.({ granted: true });
      } else if (response?.decision === "deny") {
        output?.set?.({
          granted: false,
          reason: response.reason ?? "Denied via CodeIsland",
        });
      }
      // decision === "ask" or no response → opencode shows its own UI
    },
  };
};
