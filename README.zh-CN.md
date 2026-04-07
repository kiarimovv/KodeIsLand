<div align="center">

<img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="CodeIsland" />

# CodeIsland

**你的 AI 代理住在刘海里。**

这是一个纯粹出于个人兴趣开发的项目，**完全免费开源**，没有任何商业目的。欢迎大家试用、提 Bug、推荐给身边的同事使用，也欢迎贡献代码。一起把它做得更好！

**如果觉得好用，请点个 Star 支持一下！这是我们持续更新的最大动力。**

[![GitHub stars](https://img.shields.io/github/stars/kiarimovv/KodeIsLand?style=social)](https://github.com/kiarimovv/KodeIsLand/stargazers)

[![Release](https://img.shields.io/github/v/release/kiarimovv/KodeIsLand?style=flat-square&color=4ADE80)](https://github.com/kiarimovv/KodeIsLand/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/kiarimovv/KodeIsLand/releases)
[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green?style=flat-square)](LICENSE.md)

[English](README.md) | 中文

</div>

---

一款原生 macOS 应用，将你的 MacBook 刘海变成 AI 编码代理的实时控制面板。监控会话、审批权限、跳转终端、直接发消息 — 无需离开当前工作流。

## 功能特性

### 灵动岛刘海

收起状态一眼掌握全局：

- **动画宠物** — 你的 Claude Code `/buddy` 宠物渲染为 16x16 像素画，带波浪/消散/重组动画
- **状态指示点** — 颜色表示状态：
  - 🟦 青色 = 工作中
  - 🟧 琥珀色 = 等待审批
  - 🟩 绿色 = 完成 / 等待输入
  - 🟣 紫色 = 思考中
  - 🔴 红色 = 出错，或会话超过 60 秒无人处理
  - 🟠 橙色 = 会话超过 30 秒无人处理
- **项目名 + 状态** — 轮播显示任务标题、工具动态、项目名
- **会话数量** — `×3` 角标显示活跃会话数
- **像素猫模式** — 可切换显示手绘像素猫或宠物 emoji 动画

### 会话列表

展开刘海查看所有会话：

- **来源标签** — **CC**（蓝色）= Claude Code，**OC**（紫色）= OpenCode，自动识别
- **终端标签** — 彩色显示终端类型（cmux 蓝、Ghostty 紫、iTerm 绿、Warp 琥珀等）
- **任务标题** — 显示最新用户消息或 Claude 摘要，而不只是文件夹名
- **运行时长** — 活跃会话用状态色显示
- **终端跳转** — 绿色按钮一键跳到对应终端标签页
- **关闭按钮** — 所有会话（包括活跃中）都有 × 按钮，从 CodeIsland 移除，不终止实际进程
- **Subagent 追踪** — ⚡ 标签 + 可折叠的子 Agent 工具列表
- **内联审批** — 权限请求直接在会话行显示允许/拒绝按钮

### OpenCode 支持

与 [OpenCode](https://opencode.ai) 并列的一级支持：

- **自动检测** — 通过 session ID 前缀（`ses_`）识别 OpenCode 会话，无需手动配置
- **OC 标签** — 紫色 **OC** 标签区分 OpenCode 和 Claude Code（**CC**）
- **会话标题** — 从 OpenCode 的 SQLite 数据库读取对话标题和内容
- **插件自动安装** — `codeisland-opencode.mjs` 自动安装到 `~/.config/opencode/plugins/`
- **权限审批** — Allow/Deny 同样适用于 OpenCode 的权限请求
- **直接输入** — 可在任意 OpenCode 会话中直接打字发消息

### 直接对话输入

在对话框里直接打字，不用切换终端：

- **输入框** — 始终显示在对话视图底部，打开时自动聚焦
- **发送按钮** — 开始输入后出现，按 Enter 或点击 ↑ 发送
- **智能路由** — 依次尝试：iTerm2 AppleScript（精准定位到 tty，不抢焦点）→ Terminal.app → cmux CLI → 剪贴板兜底
- **状态感知** — Claude/OpenCode 处理中时输入框自动禁用

### 权限审批

直接在刘海中审批权限请求：

- **代码差异预览** — 绿色/红色行高亮，允许前看清楚改了什么
- **拒绝/允许按钮** — 带键盘快捷键提示
- **修复可靠性** — Python hook 现在直接转发 `tool_use_id`，彻底消除点"允许"没反应的问题

### Claude Code 宠物集成

与 Claude Code 的 `/buddy` 伙伴系统完整集成：

- **精确属性** — 物种、稀有度、眼型、帽子、闪光状态和全部 5 项属性，使用与 Claude Code 完全相同的算法计算
- **动态盐值检测** — 支持修改过的安装（兼容 any-buddy）
- **ASCII 精灵动画** — 全部 18 种宠物物种，带空闲动画
- **宠物卡片** — ASCII 精灵 + 属性条 + 性格描述
- **稀有度星级** — ★ 普通 到 ★★★★★ 传说

### 像素猫伙伴

手绘像素猫，6 种动画状态：

| 状态 | 表情 |
|------|------|
| 空闲 | 黑色眼睛，每 90 帧温柔眨眼 |
| 工作中 | 眼球左/中/右移动（阅读代码） |
| 需要你 | 眼睛 + 右耳抖动 |
| 思考中 | 闭眼，鼻子呼吸 |
| 出错 | 红色 X 眼 |
| 完成 | 绿色爱心眼 + 绿色调叠加 |

### 8-bit 音效系统

每个事件的芯片音乐提醒，每个声音可单独开关，支持全局静音和音量控制。

### 智能弹出抑制

Claude 会话完成时智能判断是否弹出通知，正在看的终端不弹出。

## 终端支持

| 终端 | 检测 | 跳转 | 直接输入 | 智能抑制 |
|------|------|------|---------|---------|
| cmux | 自动 | workspace 精确跳转 | ✅ | workspace 级别 |
| iTerm2 | 自动 | AppleScript (tty 精确) | ✅ 不抢焦点 | session 级别 |
| Terminal.app | 自动 | AppleScript | ✅ | tab 级别 |
| Ghostty | 自动 | AppleScript | 剪贴板兜底 | 窗口级别 |
| Warp | 自动 | 激活 | 剪贴板兜底 | - |
| Kitty | 自动 | CLI | 剪贴板兜底 | - |
| WezTerm | 自动 | CLI | 剪贴板兜底 | - |
| VS Code | 自动 | 激活 | 剪贴板兜底 | - |
| Cursor | 自动 | 激活 | 剪贴板兜底 | - |

> **推荐搭配 [cmux](https://cmux.io)** — 基于 Ghostty 的现代终端复用器。CodeIsland 与 cmux 配合最佳：精确到 workspace 级别的跳转、AskUserQuestion 快捷回复、智能弹出抑制。多会话管理的理想组合。

## 安装

从 [Releases](https://github.com/kiarimovv/KodeIsLand/releases) 下载最新 `.dmg`，解压后拖到应用程序文件夹。

> **macOS 门禁提示：** 如果看到"Code Island 已损坏，无法打开"，在终端中运行：
> ```bash
> sudo xattr -rd com.apple.quarantine /Applications/Code\ Island.app
> ```

### 从源码构建

```bash
git clone https://github.com/kiarimovv/KodeIsLand.git
cd KodeIsLand
xcodebuild -project ClaudeIsland.xcodeproj -scheme ClaudeIsland \
  -configuration Release CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" build
```

### 系统要求

- macOS 14+（Sonoma）
- 带刘海的 MacBook（外接显示器使用浮动模式）
- [Bun](https://bun.sh) 用于精确宠物属性（可选，缺少时回退到基础信息）

## 工作原理

1. **零配置** — 首次启动时自动安装 Claude Code hook（`~/.claude/settings.json`）和 OpenCode 插件（`~/.config/opencode/plugins/`）
2. **Hook 事件** — Python 脚本（`codeisland-state.py`）通过 Unix socket（`/tmp/codeisland.sock`）发送 Claude Code 会话状态；MJS 插件为 OpenCode 做同样的事
3. **会话识别** — UUID 格式 = Claude Code；`ses_` 前缀 = OpenCode
4. **权限审批** — socket 保持连接直到用户点击允许/拒绝，再把决定发回给 Claude Code / OpenCode
5. **直接输入** — 对话框中输入的文字通过 AppleScript 或 cmux CLI 发送到终端
6. **终端跳转** — AppleScript 按 tty 或工作目录精确定位并聚焦对应终端标签

## 参与贡献

欢迎参与！

1. **提交 Bug** — 在 [Issues](https://github.com/kiarimovv/KodeIsLand/issues) 中描述问题和复现步骤
2. **提交 PR** — Fork 本仓库，新建分支，修改后提交 Pull Request
3. **建议功能** — 在 Issues 中提出，标记为 `enhancement`

## Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=kiarimovv/KodeIsLand&type=Date)](https://star-history.com/#kiarimovv/KodeIsLand&Date)

## 许可证

CC BY-NC 4.0 — 个人免费使用，禁止商业用途。
