import { Cat, Zap, ShieldCheck, Monitor, Terminal, Bell, Activity, Globe } from "lucide-react"
import type { LucideIcon } from "lucide-react"

const features: { Icon: LucideIcon; title: string; desc: string; ascii: string }[] = [
  {
    Icon: Monitor,
    ascii: `[● ● ●]
[  ...  ]
[_______]`,
    title: "灵动岛实时监控",
    desc: "折叠态左右翼显示状态圆点、Buddy 图标、项目名。青色=进行中，绿色=完成，红色=出错。",
  },
  {
    Icon: ShieldCheck,
    ascii: ` [+3 -1]
 ───────
  allow`,
    title: "刘海内审批",
    desc: "Claude 要权限？代码改了啥一目了然，diff 高亮预览，一键批准或拒绝，不用切窗口。",
  },
  {
    Icon: Activity,
    ascii: `5h 74%
7d 89%
 ████`,
    title: "智能摘要 + 用量统计",
    desc: "不用展开就能看到 Claude 在聊什么。实时显示 API 用量，帮你盯着额度别超了。",
  },
  {
    Icon: Terminal,
    ascii: `  > _
 jump!
  > _`,
    title: "一键跳转终端",
    desc: "自动识别 Ghostty、iTerm2、Warp、Terminal 等十几种终端，精确跳到对应标签页。",
  },
  {
    Icon: Cat,
    ascii: `/\\_/\\
( o.o )
 > ^ <`,
    title: "Buddy 宠物 + 像素猫",
    desc: "你的 Claude Buddy 住在刘海里，18 种物种 ASCII 动画。还有手绘像素猫 6 种表情状态。",
  },
  {
    Icon: Bell,
    ascii: `  .-.
 | ! |
  '-'`,
    title: "8-bit 音效 + 无人值守告警",
    desc: "每个事件专属芯片音提醒。超过 30 秒未处理变橙色，60 秒变红色，离开工位也放心。",
  },
  {
    Icon: Zap,
    ascii: `  [*]
  /|\\
 / | \\`,
    title: "零配置即用",
    desc: "启动一次，自动安装 hooks。不用改配置文件，不用装额外依赖。",
  },
  {
    Icon: Globe,
    ascii: ` 中/EN
 ─────
  auto`,
    title: "中英双语",
    desc: "跟随系统语言自动切换，也可以在设置里手动选择。",
  },
]

export default function Features() {
  return (
    <section id="features" className="relative py-32 px-6 noise">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_0%,rgba(124,58,237,0.06)_0%,transparent_60%)]" />

      <div className="max-w-6xl mx-auto relative z-10">
        <div
          style={{ animation: 'heroEnter 0.8s ease-out both' }}
          className="text-center mb-20"
        >
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">功能特性</span>
          <h2 className="font-display text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">
            全部塞进刘海里
          </h2>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {features.map((f, i) => (
            <div
              key={f.title}
              style={{ animation: `heroEnter 0.6s ease-out ${i * 0.08}s both` }}
              className="group glass rounded-2xl p-7 transition-all duration-500 hover:translate-y-[-4px] hover:shadow-[0_20px_60px_rgba(124,58,237,0.08)]"
            >
              {/* Icon + ASCII side by side */}
              <div className="flex items-start justify-between mb-5">
                <div className="w-10 h-10 rounded-xl bg-green/10 border border-green/15 flex items-center justify-center">
                  <f.Icon size={18} className="text-green" />
                </div>
                <pre className="font-mono text-[10px] leading-tight text-purple-light/30 group-hover:text-green/40 transition-colors duration-500 text-right">
                  {f.ascii}
                </pre>
              </div>

              <h3 className="font-display text-lg font-bold text-text-primary group-hover:text-green transition-colors duration-300">
                {f.title}
              </h3>
              <p className="text-sm text-text-muted mt-2 leading-relaxed">
                {f.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
