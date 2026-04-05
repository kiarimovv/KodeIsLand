import { useState, useEffect, useCallback } from "react"
import { motion, AnimatePresence } from "motion/react"
import { LayoutGrid, ShieldCheck, MessageSquare, ArrowRight } from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { useI18n } from "../lib/i18n"
import logo from "../lib/logo"

type DemoState = "monitor" | "approve" | "ask" | "jump"

const pillDefs: { id: DemoState; labelKey: string; Icon: LucideIcon }[] = [
  { id: "monitor", labelKey: "demo.monitor", Icon: LayoutGrid },
  { id: "approve", labelKey: "demo.approve", Icon: ShieldCheck },
  { id: "ask", labelKey: "demo.ask", Icon: MessageSquare },
  { id: "jump", labelKey: "demo.jump", Icon: ArrowRight },
]

function MonitorView() {
  const { t } = useI18n()
  return (
    <div className="space-y-3">
      <div className="text-xs text-text-muted font-mono mb-4">{t("demo.activeSessions")}</div>
      {[
        { name: "fix auth bug", status: "working", tool: "Bash: npm test", time: "12m", color: "bg-green" },
        { name: "optimize queries", status: "waiting", tool: "Read: schema.prisma", time: "5m", color: "bg-amber" },
      ].map((s) => (
        <div key={s.name} className="flex items-center gap-3 p-3 rounded-lg bg-white/[0.03] border border-white/[0.04]">
          <div className={`w-2 h-2 rounded-full ${s.color} shrink-0`} style={{ boxShadow: s.color === 'bg-green' ? '0 0 8px rgba(52,211,153,0.5)' : '0 0 8px rgba(251,191,36,0.5)' }} />
          <div className="flex-1 min-w-0">
            <div className="text-sm text-text-primary font-medium truncate">{s.name}</div>
            <div className="text-xs text-text-muted font-mono">{s.tool}</div>
          </div>
          <span className="text-xs text-text-muted font-mono shrink-0">{s.time}</span>
        </div>
      ))}
    </div>
  )
}

function ApproveView() {
  const { t } = useI18n()
  return (
    <div className="space-y-3">
      <div className="text-xs text-amber font-mono flex items-center gap-2">
        <ShieldCheck size={12} /> {t("demo.permissionRequest")}
      </div>
      <div className="text-xs text-text-muted font-mono">Edit: src/auth/middleware.ts</div>
      <div className="rounded-lg overflow-hidden border border-white/[0.06] text-xs font-mono">
        <div className="bg-red-500/10 text-red-400 px-3 py-1.5 border-b border-white/[0.04]">
          - jwt.verify(token);
        </div>
        <div className="bg-green/10 text-green px-3 py-1.5">
          + if (!token) throw new AuthError('missing');
        </div>
      </div>
      <div className="flex gap-2 pt-1">
        <button className="flex-1 py-2 rounded-lg bg-green/15 text-green text-xs font-mono border border-green/20 hover:bg-green/25 transition-colors">{t("demo.allow")}</button>
        <button className="flex-1 py-2 rounded-lg bg-red-500/10 text-red-400 text-xs font-mono border border-red-500/15 hover:bg-red-500/15 transition-colors">{t("demo.deny")}</button>
      </div>
    </div>
  )
}

function AskView() {
  const { t } = useI18n()
  return (
    <div className="space-y-3">
      <div className="text-xs text-purple-light font-mono flex items-center gap-2">
        <MessageSquare size={12} /> {t("demo.claudeAsking")}
      </div>
      <div className="p-3 rounded-lg bg-white/[0.03] border border-white/[0.04]">
        <p className="text-sm text-text-secondary leading-relaxed">
          "{t("demo.claudeQuestion")}"
        </p>
      </div>
      <div className="flex gap-2">
        <button className="flex-1 py-2 rounded-lg bg-green/15 text-green text-xs font-mono border border-green/20">{t("demo.yes")}</button>
        <button className="flex-1 py-2 rounded-lg bg-amber/10 text-amber text-xs font-mono border border-amber/15">{t("demo.no")}</button>
        <button className="flex-1 py-2 rounded-lg bg-purple-accent/10 text-purple-light text-xs font-mono border border-purple-accent/15">{t("demo.jump")}</button>
      </div>
    </div>
  )
}

function JumpView() {
  const { t } = useI18n()
  return (
    <div className="space-y-3">
      <div className="text-xs text-green font-mono flex items-center gap-2">
        <ArrowRight size={12} /> {t("demo.jumpToTerminal")}
      </div>
      <div className="p-4 rounded-lg bg-white/[0.03] border border-white/[0.04] text-center">
        <div className="font-mono text-2xl text-green glow-green mb-2">→→→</div>
        <div className="text-sm text-text-primary font-medium">fix-auth-bug</div>
        <div className="text-xs text-text-muted font-mono mt-1">cmux  ·  tab 3  ·  split 1</div>
      </div>
    </div>
  )
}

const views: Record<DemoState, React.FC> = { monitor: MonitorView, approve: ApproveView, ask: AskView, jump: JumpView }

export default function NotchDemo() {
  const { t } = useI18n()
  const [active, setActive] = useState<DemoState>("monitor")
  const [paused, setPaused] = useState(false)

  const descMap: Record<DemoState, { titleKey: string; subKey: string }> = {
    monitor: { titleKey: "demo.monitorTitle", subKey: "demo.monitorSub" },
    approve: { titleKey: "demo.approveTitle", subKey: "demo.approveSub" },
    ask: { titleKey: "demo.askTitle", subKey: "demo.askSub" },
    jump: { titleKey: "demo.jumpTitle", subKey: "demo.jumpSub" },
  }

  const cycle = useCallback(() => {
    setActive((p) => {
      const idx = pillDefs.findIndex((x) => x.id === p)
      return pillDefs[(idx + 1) % pillDefs.length].id
    })
  }, [])

  useEffect(() => {
    if (paused) return
    const timer = setInterval(cycle, 4000)
    return () => clearInterval(timer)
  }, [paused, cycle])

  const pick = (id: DemoState) => {
    setActive(id)
    setPaused(true)
    setTimeout(() => setPaused(false), 12000)
  }

  const View = views[active]
  const desc = descMap[active]

  return (
    <section id="demo" className="relative z-20 py-20 sm:py-32 px-4 sm:px-6 noise bg-deep">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_50%,rgba(124,58,237,0.05)_0%,transparent_70%)]" />

      <div className="max-w-3xl mx-auto relative z-10">
        <div style={{ animation: 'heroEnter 0.8s ease-out both' }} className="text-center mb-12 sm:mb-16">
          <span className="font-mono text-xs text-green uppercase tracking-[0.3em]">{t("demo.sectionTag")}</span>
          <h2 className="font-display text-3xl sm:text-4xl sm:text-5xl font-extrabold text-text-primary mt-4">{t("demo.sectionTitle")}</h2>
        </div>

        {/* Notch mockup */}
        <div style={{ animation: 'heroEnter 0.8s ease-out 0.1s both' }} className="mx-auto max-w-md">
          <div className="relative">
            <div className="bg-black rounded-b-3xl pt-3 pb-5 px-5 border border-white/[0.06] border-t-0 shadow-[0_20px_80px_rgba(0,0,0,0.6),0_0_0_1px_rgba(255,255,255,0.03)_inset]">
              <div className="flex items-center justify-between mb-4 pb-3 border-b border-white/[0.05]">
                <div className="flex items-center gap-2">
                  <img src={logo} alt="" className="w-6 h-6 rounded-sm" />
                  <span className="font-mono text-xs text-text-secondary">myproject</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <div className="w-1.5 h-1.5 rounded-full bg-green" style={{ boxShadow: '0 0 6px rgba(52,211,153,0.5)' }} />
                  <span className="font-mono text-[10px] text-text-muted">2 {t("demo.active")}</span>
                </div>
              </div>

              <AnimatePresence mode="wait">
                <motion.div key={active} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} transition={{ duration: 0.25 }} className="min-h-[180px]">
                  <View />
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>

        {/* Pills */}
        <div className="flex flex-wrap justify-center gap-2 mt-8 sm:mt-10">
          {pillDefs.map((p) => (
            <button
              key={p.id}
              onClick={() => pick(p.id)}
              className={`flex items-center gap-1.5 font-mono text-xs px-3 sm:px-4 py-2 rounded-full border transition-all duration-300 cursor-pointer ${
                active === p.id
                  ? "bg-green/10 border-green/25 text-green shadow-[0_0_16px_rgba(52,211,153,0.1)]"
                  : "border-white/[0.06] text-text-muted hover:border-white/[0.12] hover:text-text-secondary"
              }`}
            >
              <p.Icon size={12} />
              {t(p.labelKey as any)}
            </button>
          ))}
        </div>

        {/* Description */}
        <AnimatePresence mode="wait">
          <motion.div key={active} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }} className="text-center mt-6 sm:mt-8 px-4">
            <h3 className="font-display text-xl sm:text-2xl font-bold text-text-primary">{t(desc.titleKey as any)}</h3>
            <p className="text-sm text-text-muted mt-2 max-w-md mx-auto">{t(desc.subKey as any)}</p>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
