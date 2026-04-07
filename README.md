<div align="center">

<img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="CodeIsland" />

# CodeIsland (个人修改版)

**基于 [xmqywx/CodeIsland](https://github.com/xmqywx/CodeIsland) 的个人修改版本，仅供自用。**

原项目是一个将 MacBook 刘海屏变成 AI 编程助手实时控制面板的 macOS 原生应用。
本仓库在原版基础上做了若干功能增强和体验优化，主要围绕 **OpenCode 支持**、**会话管理**、**直接输入增强** 等方面。

</div>

---

## 原版项目

- **原版仓库**: [https://github.com/xmqywx/CodeIsland](https://github.com/xmqywx/CodeIsland)
- **原作者**: [xmqywx](https://github.com/xmqywx)
- **协议**: CC BY-NC 4.0

感谢原作者的优秀工作，本修改版完全基于原版开发。

---

## 相比原版的修改内容

### 新增功能

#### OpenCode 一级支持
- 自动检测 OpenCode 会话（session ID `ses_` 前缀识别）
- **OC** 紫色标签 / **CC** 蓝色标签区分会话来源
- 自动安装 `codeisland-opencode.mjs` 插件到 `~/.config/opencode/plugins/`
- 从 OpenCode SQLite 数据库读取会话标题和对话内容
- Copilot 用量监控（GitHub Copilot 配额读取）

#### 直接对话输入增强
- 对话框底部常驻输入框，打开时自动聚焦
- 发送路由增强：iTerm2 AppleScript → Terminal.app → **tmux send-keys** → **Ghostty 剪贴板粘贴** → cmux CLI → 剪贴板兜底
- Claude/OpenCode 处理中自动禁用输入

#### Zombie Session 检测
- PosixLivenessChecker（`kill -0`）存活检查，5 秒间隔扫描
- 自动标记死亡会话为 `.ended`，取消挂起的权限/中断监听
- "Clear Ended" 按钮一键清除已结束会话

#### JSONL 中断监听增强
- 支持父目录遍历查找 JSONL 文件路径（匹配 ConversationParser 行为）
- 新增 `result` 级别错误检测（`is_error: true`）
- 新增 `Cancelled` / `cancelled` 中断关键词

### 体验优化

#### 审批 UI 布局优化
- 审批按钮（Allow/Deny、选项按钮）提升至标题正下方，无需滚动即可操作
- 审批状态下隐藏副标题和工具信息，减少视觉干扰
- 审批会话数独立追踪，面板高度动态适配

#### 会话管理增强
- 所有会话（含活跃中）均显示 × 关闭按钮（仅从 CodeIsland 移除，不终止进程）
- 已结束会话显示 "Ended" 标签、降低透明度（0.4）、隐藏终端跳转按钮
- CC/OC 来源标签始终可见

#### 菜单面板清理
- 移除底部微信号和推广文字
- Buddy + UsageStatsBar 改为 VStack 底部流式布局（不再浮动遮挡会话列表）
- 菜单基础高度 440→400，匹配实际内容

### Bug 修复

- **权限审批 "允许" 无效**: Python hook 的 PermissionRequest 现在直接转发 `tool_use_id`，消除缓存 key 不匹配导致的静默失败
- **OpenCode 会话误判为子会话**: 移除 cwd 备选匹配逻辑，仅保留精确 pid 匹配
- **NotchView 格式修正**: 清理多余空行

---

## 修改的文件列表

以下文件相比原版 ([xmqywx/CodeIsland@main](https://github.com/xmqywx/CodeIsland)) 有修改：

### Swift 源码

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `ClaudeIsland/Core/NotchViewModel.swift` | 修改 | 新增 `approvalSessionCount` 追踪，面板高度动态适配 |
| `ClaudeIsland/Core/DebugLogger.swift` | 修改 | Swift 6 Sendable + nonisolated 修复 |
| `ClaudeIsland/Core/Localization.swift` | 修改 | 新增 ended / clearEnded 本地化字符串 |
| `ClaudeIsland/Models/SessionEvent.swift` | 修改 | 新增 `clearEndedSessions` 事件 |
| `ClaudeIsland/Models/SessionState.swift` | 修改 | 新增 `source` 字段、OpenCode 会话识别 |
| `ClaudeIsland/Services/Session/ClaudeSessionMonitor.swift` | 修改 | zombie scan 启动，间隔 5s |
| `ClaudeIsland/Services/Session/JSONLInterruptWatcher.swift` | 修改 | 父目录遍历、result error 检测、新增中断关键词 |
| `ClaudeIsland/Services/State/SessionStore.swift` | 修改 | zombie scan、clearEndedSessions、OpenCode 识别 |
| `ClaudeIsland/Services/Hooks/HookSocketServer.swift` | 修改 | OpenCode 事件处理 |
| `ClaudeIsland/Services/Shared/TerminalAppRegistry.swift` | 修改 | 终端检测增强 |
| `ClaudeIsland/Services/Window/TerminalJumper.swift` | 修改 | 跳转逻辑增强 |
| `ClaudeIsland/UI/Views/ChatView.swift` | 修改 | 直接输入 + tmux/Ghostty 发送支持 |
| `ClaudeIsland/UI/Views/ClaudeInstancesView.swift` | 修改 | 审批 UI 布局优先、CC/OC 标签、×按钮、ended 样式 |
| `ClaudeIsland/UI/Views/NotchMenuView.swift` | 修改 | 移除推广文字、Buddy 布局调整 |
| `ClaudeIsland/UI/Views/NotchView.swift` | 修改 | 格式清理 |
| `ClaudeIsland/App/AppDelegate.swift` | 修改 | OpenCode 插件安装逻辑 |
| `ClaudeIsland/Resources/codeisland-state.py` | 修改 | tool_use_id 转发修复 |

### 新增文件

| 文件 | 说明 |
|------|------|
| `ClaudeIsland/Resources/codeisland-opencode.mjs` | OpenCode 插件 |
| `ClaudeIsland/Services/Hooks/OpenCodeHookInstaller.swift` | OpenCode 插件安装器 |
| `ClaudeIsland/Services/Session/CopilotQuotaMonitor.swift` | Copilot 用量监控 |
| `ClaudeIsland/Services/Session/OpenCodeConversationParser.swift` | OpenCode SQLite 对话解析 |
| `ClaudeIsland/Services/State/ProcessLivenessChecker.swift` | 进程存活检查器 |
| `ClaudeIsland/UI/Helpers/SessionFilter.swift` | 会话过滤辅助 |

### 删除的文件

| 文件 | 说明 |
|------|------|
| `ClaudeIsland/Services/Session/RateLimitMonitor.swift` | 替换为 CopilotQuotaMonitor |
| `ClaudeIsland/Core/SoundManager.swift` | 音效管理移除（部分功能） |

### 其他

| 文件 | 说明 |
|------|------|
| `landing/` | 官网 landing page（含国际化、MacBook mockup、社区弹窗等） |
| `.github/workflows/deploy-landing.yml` | Landing page 部署 workflow |
| `README.md` | 重写为修改版说明 |
| `README.zh-CN.md` | 中文 README 更新 |

---

## 构建

```bash
git clone https://github.com/kiarimovv/KodeIsLand.git
cd KodeIsLand
xcodebuild -project ClaudeIsland.xcodeproj -scheme ClaudeIsland \
  -configuration Release CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" build
```

### 要求

- macOS 14+ (Sonoma)
- MacBook with notch（外接显示器使用浮动模式）

---

## License

CC BY-NC 4.0 — 仅供个人使用，禁止商业用途。

原版协议见 [xmqywx/CodeIsland](https://github.com/xmqywx/CodeIsland)。
