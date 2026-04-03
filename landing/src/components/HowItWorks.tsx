import { Download, Rocket, Zap } from "lucide-react"

const steps = [
  {
    Icon: Download,
    num: "01",
    cmd: "# 下载 DMG 拖到应用程序",
    title: "安装",
    desc: "从 GitHub Releases 下载 DMG，拖到应用程序文件夹即可。",
  },
  {
    Icon: Rocket,
    num: "02",
    cmd: "# 自动配置 Claude Code hooks",
    title: "启动",
    desc: "CodeIsland 自动检测你的环境并安装 hooks，无需手动编辑任何配置文件。",
  },
  {
    Icon: Zap,
    num: "03",
    cmd: "# 监控 → 审批 → 跳转 → 心流",
    title: "专注",
    desc: "监控、审批、跳回终端——全在刘海里完成。再也不用切窗口打断思路。",
  },
]

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-32 px-6 noise">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_40%_at_50%_100%,rgba(52,211,153,0.04)_0%,transparent_60%)]" />

      <div className="max-w-5xl mx-auto relative z-10">
        <div
          style={{ animation: 'heroEnter 0.8s ease-out both' }}
          className="text-center mb-20"
        >
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">快速上手</span>
          <h2 className="font-display text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">
            三步开始
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
          {/* Connecting line */}
          <div className="hidden md:block absolute top-16 left-[16%] right-[16%] h-px bg-gradient-to-r from-transparent via-purple-accent/20 to-transparent" />

          {steps.map((step, i) => (
            <div
              key={step.num}
              style={{ animation: `heroEnter 0.6s ease-out ${i * 0.12}s both` }}
              className="text-center"
            >
              {/* Number badge */}
              <div className="relative inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-green/10 border border-green/15 mb-6">
                <step.Icon size={20} className="text-green" />
                <span className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-deep border border-green/30 flex items-center justify-center font-mono text-[9px] text-green font-bold">
                  {step.num}
                </span>
              </div>

              {/* Terminal command */}
              <div className="glass rounded-xl p-4 mb-5 text-left">
                <div className="flex items-center gap-1.5 mb-2">
                  <div className="w-2 h-2 rounded-full bg-red-400/60" />
                  <div className="w-2 h-2 rounded-full bg-amber/60" />
                  <div className="w-2 h-2 rounded-full bg-green/60" />
                </div>
                <code className="font-mono text-xs text-green/80 leading-relaxed block">
                  <span className="text-purple-light/40">$</span> {step.cmd}
                </code>
              </div>

              <h3 className="font-display text-xl font-bold text-text-primary">{step.title}</h3>
              <p className="text-sm text-text-muted mt-2 leading-relaxed">{step.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
