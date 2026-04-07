<div align="center">

<img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="CodeIsland" />

# CodeIsland

**Your AI agents live in the notch.**

This is a passion project built purely out of personal interest. It is **free and open-source** with no commercial intentions whatsoever. I welcome everyone to try it out, report bugs, share it with your colleagues, and contribute code. Let's build something great together!

这是一个纯粹出于个人兴趣开发的项目，**完全免费开源**，没有任何商业目的。欢迎大家试用、提 Bug、推荐给身边的同事使用，也欢迎贡献代码。一起把它做得更好！

English | [中文](README.zh-CN.md)

[![GitHub stars](https://img.shields.io/github/stars/kiarimovv/KodeIsLand?style=social)](https://github.com/kiarimovv/KodeIsLand/stargazers)

[![Release](https://img.shields.io/github/v/release/kiarimovv/KodeIsLand?style=flat-square&color=4ADE80)](https://github.com/kiarimovv/KodeIsLand/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/kiarimovv/KodeIsLand/releases)
[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green?style=flat-square)](LICENSE.md)

**If you find this useful, please give it a star! It keeps us motivated to improve.**

**如果觉得好用，请点个 Star 支持一下！这是我们持续更新的最大动力。**

</div>

---

A native macOS app that turns your MacBook's notch into a real-time control surface for AI coding agents. Monitor sessions, approve permissions, jump to terminals, chat directly — all without leaving your flow.

## Features

### Dynamic Island Notch

The collapsed notch shows everything at a glance:

- **Animated buddy** — your Claude Code `/buddy` pet rendered as 16x16 pixel art
- **Status dot** — color indicates state:
  - 🟦 Cyan = working
  - 🟧 Amber = needs approval
  - 🟩 Green = done / waiting for input
  - 🟣 Purple = thinking
  - 🔴 Red = error, or session unattended >60s
  - 🟠 Orange = session unattended >30s
- **Project name + status** — carousel rotates task title, tool action, project name
- **Session count** — `×3` badge showing active sessions

### Session List

Expand the notch to see all your sessions:

- **Source badges** — **CC** (blue) for Claude Code, **OC** (purple) for OpenCode — auto-detected
- **Auto-detected terminal** — colored tag: Ghostty, Warp, iTerm2, cmux, Terminal, VS Code, Cursor, etc.
- **Task title** — displays your latest message or Claude's summary, not just the folder name
- **Duration badge** — how long each session has been running
- **Terminal jump button** — click to jump to the exact terminal tab
- **Dismiss button** — × on every session (including active ones) to hide from CodeIsland without killing the process
- **Subagent tracking** — ⚡ badge + collapsible sub-agent tool list
- **Inline approval** — Allow/Deny buttons appear inline for permission requests

### OpenCode Support

First-class support for [OpenCode](https://opencode.ai) alongside Claude Code:

- **Auto-detection** — OpenCode sessions detected by session ID format (`ses_` prefix) — no manual config
- **OC badge** — purple **OC** label distinguishes OpenCode from Claude Code (**CC**) sessions
- **Conversation display** — reads titles and messages from OpenCode's SQLite database
- **Plugin** — `codeisland-opencode.mjs` installed automatically to `~/.config/opencode/plugins/`
- **Permission approval** — Allow/Deny works for OpenCode permission requests
- **Direct chat input** — type messages straight into any OpenCode session

### Direct Chat Input

Type messages directly in the chat dialog — no terminal switching needed:

- **Input bar** — always visible at the bottom of the chat view; auto-focuses when opened
- **Send button** — appears when you start typing; press Enter or click ↑ to send
- **Smart routing** — sends via iTerm2 AppleScript (by tty, no window focus), Terminal.app, cmux CLI, or clipboard fallback
- **State-aware** — input disabled while Claude/OpenCode is processing

### Permission Approval

Approve or deny permission requests right from the notch:

- **Code diff preview** — see exactly what will change before allowing
- **Deny/Allow buttons** — with keyboard hint labels
- **Fixed reliability** — `tool_use_id` now forwarded directly in the Python hook, eliminating silent failures when approving

### Claude Code Buddy Integration

Full integration with Claude Code's `/buddy` companion system:

- **Accurate stats** — all 5 stats computed using the same algorithm as Claude Code
- **ASCII art sprite** — all 18 buddy species with idle animation
- **Buddy card** — ASCII sprite + stat bars + personality

### Pixel Cat Companion

A hand-drawn pixel cat with 6 animated states:

| State | Expression |
|-------|-----------|
| Idle | Black eyes, gentle blink every 90 frames |
| Working | Eyes dart left/center/right |
| Needs You | Eyes + right ear twitches |
| Thinking | Closed eyes, breathing nose |
| Error | Red X eyes |
| Done | Green heart eyes + green tint overlay |

### 8-bit Sound System

Chiptune alerts for every event. Each sound can be toggled individually.

### Project Grouping

Toggle between flat list and project-grouped view. Sessions automatically grouped by working directory.

## Settings

| Setting | Description |
|---------|-------------|
| **Screen** | Choose which display shows the notch |
| **Notification Sound** | Select alert sound style |
| **Group by Project** | Toggle between flat list and project-grouped sessions |
| **Pixel Cat Mode** | Switch notch icon between pixel cat and buddy emoji animation |
| **Language** | Auto (system) / English / 中文 |
| **Launch at Login** | Start CodeIsland automatically when you log in |
| **Hooks** | Install/uninstall Claude Code hooks in `~/.claude/settings.json` |
| **Accessibility** | Grant accessibility permission for terminal window focusing |

## Terminal Support

CodeIsland auto-detects your terminal from the process tree:

| Terminal | Detection | Jump-to-Tab | Direct Input |
|----------|-----------|-------------|--------------|
| cmux | Auto | AppleScript (workspace level) | ✅ |
| iTerm2 | Auto | AppleScript (by tty) | ✅ no focus steal |
| Terminal.app | Auto | AppleScript | ✅ |
| Ghostty | Auto | AppleScript | clipboard fallback |
| Warp | Auto | Activate only | clipboard fallback |
| Kitty | Auto | CLI | clipboard fallback |
| WezTerm | Auto | CLI | clipboard fallback |
| VS Code | Auto | Activate | clipboard fallback |
| Cursor | Auto | Activate | clipboard fallback |

> **Recommended: [cmux](https://cmux.io)** — A modern terminal multiplexer built on Ghostty. CodeIsland works best with cmux: precise workspace-level jumping, AskUserQuestion quick reply, and smart popup suppression per workspace tab.

## Install

**Download** the latest `.dmg` from [Releases](https://github.com/kiarimovv/KodeIsLand/releases), open it, drag to Applications.

> **macOS Gatekeeper warning:** If you see "Code Island is damaged and can't be opened", run:
> ```bash
> sudo xattr -rd com.apple.quarantine /Applications/Code\ Island.app
> ```

### Build from Source

```bash
git clone https://github.com/kiarimovv/KodeIsLand.git
cd KodeIsLand
xcodebuild -project ClaudeIsland.xcodeproj -scheme ClaudeIsland \
  -configuration Release CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" build
```

### Requirements

- macOS 14+ (Sonoma)
- MacBook with notch (floating mode on external displays)
- [Bun](https://bun.sh) for accurate buddy stats (optional)

## How It Works

1. **Zero config** — on first launch, CodeIsland installs hooks into `~/.claude/settings.json` and the OpenCode plugin into `~/.config/opencode/plugins/`
2. **Hook events** — a Python script (`codeisland-state.py`) sends Claude Code session state via Unix socket (`/tmp/codeisland.sock`); the MJS plugin does the same for OpenCode
3. **Session detection** — Claude Code sessions identified by UUID format; OpenCode sessions by `ses_` prefix
4. **Permission approval** — socket stays open until you click Allow/Deny, then sends the decision back
5. **Direct input** — text typed in the chat view is sent to the terminal via AppleScript or cmux CLI
6. **Terminal jump** — AppleScript finds and focuses the correct terminal tab by tty or working directory

## Contributing

Contributions are welcome!

1. **Report bugs** — [Open an issue](https://github.com/kiarimovv/KodeIsLand/issues)
2. **Submit a PR** — Fork the repo, create a branch, make your changes
3. **Suggest features** — Open an issue tagged `enhancement`

## 参与贡献

欢迎参与！

1. **提交 Bug** — 在 [Issues](https://github.com/kiarimovv/KodeIsLand/issues) 中描述问题
2. **提交 PR** — Fork 本仓库，新建分支，修改后提交 Pull Request
3. **建议功能** — 在 Issues 中提出，标记为 `enhancement`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=kiarimovv/KodeIsLand&type=Date)](https://star-history.com/#kiarimovv/KodeIsLand&Date)

## License

CC BY-NC 4.0 — free for personal use, no commercial use.
