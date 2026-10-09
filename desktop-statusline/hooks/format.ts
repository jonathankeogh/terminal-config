// Pure formatting for the desktop status line. The Code tab already shows the
// repo, branch, model and effort beside the prompt, and gives a plugin's line
// only a narrow slot, so this keeps just the figures statusline-command.sh adds
// on top: cost, rate limits, context and prompt-cache time left.

export type Figures = {
  costUsd?: number
  fiveHourPct?: number
  weekPct?: number
  contextPct?: number
  autocompactPct: number
  // Seconds of prompt cache left, and the window it counts down from.
  cacheLeft?: number
  cacheTtl?: number
}

export const formatStatus = (f: Figures): string => {
  const segments: string[] = []

  if (f.costUsd !== undefined) segments.push(`$${f.costUsd.toFixed(2)}`)
  if (f.fiveHourPct !== undefined) segments.push(`${Math.round(f.fiveHourPct)}% sess`)
  if (f.weekPct !== undefined) segments.push(`${Math.round(f.weekPct)}% wk`)

  if (f.contextPct !== undefined) {
    const used = Math.round(f.contextPct)
    // The terminal turns this red within 10 points of auto-compact; with no
    // colour here, a marker stands in.
    const warn = used >= f.autocompactPct - 10 ? '⚠ ' : ''
    segments.push(`ctx ${warn}${used}%`)
  }

  if (f.cacheLeft !== undefined) {
    if (f.cacheLeft <= 0) {
      segments.push('cache cold')
    } else {
      const left = Math.floor(f.cacheLeft)
      const mmss = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, '0')}`
      const isLow = f.cacheTtl !== undefined && left <= f.cacheTtl / 5
      segments.push(`cache ${isLow ? '⚠ ' : ''}${mmss}`)
    }
  }

  return segments.join(' · ')
}

// From the tail of a transcript (JSONL), the last assistant entry's time and
// cache TTL: 5 minutes if that call wrote only 5m-tier cache, else 1 hour.
export const lastCacheWrite = (
  tail: string,
): { at: number; ttl: number } | undefined => {
  const lines = tail.split('\n')
  for (let i = lines.length - 1; i >= 0; i--) {
    const raw = lines[i]
    if (!raw.includes('"assistant"')) continue
    let entry: any
    try {
      entry = JSON.parse(raw)
    } catch {
      continue
    }
    const usage = entry?.message?.usage
    if (entry?.type !== 'assistant' || !usage || !entry.timestamp) continue
    const cc = usage.cache_creation ?? {}
    const ttl =
      cc.ephemeral_5m_input_tokens && !cc.ephemeral_1h_input_tokens ? 300 : 3600
    const at = Date.parse(entry.timestamp)
    if (Number.isNaN(at)) continue
    return { at, ttl }
  }
  return undefined
}
