import { afterEach, describe, expect, it } from 'vitest'
import { THEME_STORAGE_KEY, readPreference, resolveTheme } from './theme'

describe('resolveTheme', () => {
  it('follows the system when the preference is "system"', () => {
    expect(resolveTheme('system', true)).toBe('dark')
    expect(resolveTheme('system', false)).toBe('light')
  })

  it('ignores the system when the user picked a theme', () => {
    expect(resolveTheme('light', true)).toBe('light')
    expect(resolveTheme('dark', false)).toBe('dark')
  })
})

describe('readPreference', () => {
  afterEach(() => {
    localStorage.clear()
  })

  it('defaults to "system" when nothing is stored', () => {
    expect(readPreference()).toBe('system')
  })

  it('returns the stored preference', () => {
    localStorage.setItem(THEME_STORAGE_KEY, 'dark')

    expect(readPreference()).toBe('dark')
  })

  it('falls back to "system" when the stored value is invalid', () => {
    localStorage.setItem(THEME_STORAGE_KEY, 'purple')

    expect(readPreference()).toBe('system')
  })
})
