import { expect, test } from 'claude-code/testing'

import { formatStatus, lastCacheWrite } from './format'

test('empty before any figures arrive', () => {
  expect(formatStatus({ autocompactPct: 95 })).toBe('')
})

test('all segments, in the terminal script order', () => {
  const line = formatStatus({
    costUsd: 1.234, fiveHourPct: 12.6, weekPct: 40, contextPct: 88,
    autocompactPct: 95, cacheLeft: 1925, cacheTtl: 3600,
  })
  expect(line).toBe('$1.23 · 13% sess · 40% wk · ctx ⚠ 88% · cache 32:05')
})

test('cache warns in the last fifth and goes cold at zero', () => {
  expect(formatStatus({ autocompactPct: 95, cacheLeft: 59, cacheTtl: 300 })).toBe('cache ⚠ 0:59')
  expect(formatStatus({ autocompactPct: 95, cacheLeft: 0, cacheTtl: 300 })).toBe('cache cold')
})

test('lastCacheWrite reads the last assistant entry and its tier', () => {
  const tail = [
    JSON.stringify({ type: 'assistant', timestamp: '2026-10-09T10:00:00Z', message: { usage: { cache_creation: { ephemeral_1h_input_tokens: 5 } } } }),
    JSON.stringify({ type: 'assistant', timestamp: '2026-10-09T10:05:00Z', message: { usage: { cache_creation: { ephemeral_5m_input_tokens: 5 } } } }),
    JSON.stringify({ type: 'user', timestamp: '2026-10-09T10:06:00Z' }),
  ].join('\n')
  expect(lastCacheWrite(tail)).toEqual({ at: Date.parse('2026-10-09T10:05:00Z'), ttl: 300 })
})
