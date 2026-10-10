// Mirrors statusline-command.sh in the desktop app's Code tab, which does not
// run the `statusLine` command setting. The figures the terminal script reads
// from its stdin JSON come from the plugin API here instead.
import type { EngineInterface, Register, SessionUsage } from 'claude-code'

import { formatStatus, lastCacheWrite } from './format'

// Same cadence as the terminal's refreshInterval, so the cache countdown ticks.
const REFRESH_MS = 10_000

let usage: Omit<SessionUsage, 'startedAt'> | undefined
let transcriptPath: string | undefined
let home: string | undefined

async function sh($: EngineInterface, argv: string[]) {
  const r = await $.process.run(argv, { timeoutMs: 5000 }).catch(() => undefined)
  return r?.exitCode === 0 ? r.stdout.trim() : ''
}

async function findTranscript($: EngineInterface, home: string) {
  if (transcriptPath) return transcriptPath
  const id = await $.session.id()
  const found = await sh($, [
    'find',
    `${home}/.claude/projects`,
    '-maxdepth',
    '2',
    '-name',
    `${id}.jsonl`,
  ])
  transcriptPath = found.split('\n')[0] || undefined
  return transcriptPath
}

async function refresh($: EngineInterface) {
  // Desktop only: the terminal draws statusline-command.sh, so stay off a
  // session that only a terminal is attached to.
  const surfaces = await $.session.surfaces()
  if (!surfaces.some(s => s !== 'terminal')) return $.ui.status(undefined)

  home ??= await sh($, ['sh', '-c', 'printf %s "$HOME"'])
  const settings = await $.settings.read().catch(() => ({}) as Record<string, unknown>)
  usage ??= await $.session.usage().catch(() => undefined)

  let cacheLeft: number | undefined
  let cacheTtl: number | undefined
  const path = await findTranscript($, home)
  if (path) {
    const tail = await sh($, ['tail', '-c', '2000000', path])
    const write = lastCacheWrite(tail)
    if (write) {
      const now = await $.clock.now()
      cacheTtl = write.ttl
      cacheLeft = Math.max(0, write.ttl - (now - write.at) / 1000)
    }
  }

  const env = (settings.env ?? {}) as Record<string, string>
  const pctOf = (kind: string) =>
    usage?.rateLimits.find(r => r.kind === kind)?.percentUsed

  const line = formatStatus({
    costUsd: usage?.cost?.usd,
    fiveHourPct: pctOf('five_hour'),
    weekPct: pctOf('seven_day'),
    contextPct: usage?.context.percent,
    autocompactPct: Number(env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE ?? 95) || 95,
    cacheLeft,
    cacheTtl,
  })
  // Before the first response there are no figures yet: clear rather than
  // pin an empty line.
  $.ui.status(line || undefined)
}

function safeRefresh($: EngineInterface) {
  refresh($).catch(err => $.ui.log(`${$.plugin.name}: ${String(err)}`, { to: 'debug' }))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    safeRefresh($)
    $.clock.every(REFRESH_MS, () => safeRefresh($))
    return result
  })

  on('session.measure', ($, e, next) => {
    usage = { context: e.context, rateLimits: e.rateLimits, cost: e.cost }
    safeRefresh($)
    return next(e)
  })

  on('turn.complete', ($, e, next) => {
    safeRefresh($)
    return next(e)
  })
}
