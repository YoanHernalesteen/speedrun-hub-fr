export type ThemePreference = 'light' | 'dark' | 'system'
export type ResolvedTheme = 'light' | 'dark'

// Keep in sync with the inline script in index.html, which applies the theme
// before React renders to avoid a flash of the wrong theme.
export const THEME_STORAGE_KEY = 'theme'
const DARK_QUERY = '(prefers-color-scheme: dark)'

function isPreference(value: unknown): value is ThemePreference {
  return value === 'light' || value === 'dark' || value === 'system'
}

export function readPreference(): ThemePreference {
  try {
    const stored = localStorage.getItem(THEME_STORAGE_KEY)
    return isPreference(stored) ? stored : 'system'
  } catch {
    // Storage can be blocked (privacy settings): fall back to the system.
    return 'system'
  }
}

export function resolveTheme(
  preference: ThemePreference,
  systemPrefersDark: boolean,
): ResolvedTheme {
  if (preference === 'system') return systemPrefersDark ? 'dark' : 'light'
  return preference
}

function systemPrefersDark(): boolean {
  return window.matchMedia(DARK_QUERY).matches
}

function applyTheme(preference: ThemePreference) {
  const theme = resolveTheme(preference, systemPrefersDark())
  document.documentElement.classList.toggle('dark', theme === 'dark')
  document.documentElement.style.colorScheme = theme
}

// Small external store consumed with useSyncExternalStore (see useTheme).
const listeners = new Set<() => void>()

export function setPreference(preference: ThemePreference) {
  try {
    if (preference === 'system') localStorage.removeItem(THEME_STORAGE_KEY)
    else localStorage.setItem(THEME_STORAGE_KEY, preference)
  } catch {
    // Not persisted, but still applied for the current page.
  }
  applyTheme(preference)
  listeners.forEach((listener) => listener())
}

export function subscribe(listener: () => void) {
  listeners.add(listener)

  const media = window.matchMedia(DARK_QUERY)
  const onSystemChange = () => {
    applyTheme(readPreference())
    listener()
  }
  // Another tab changed the preference.
  const onStorage = (event: StorageEvent) => {
    if (event.key !== THEME_STORAGE_KEY) return
    applyTheme(readPreference())
    listener()
  }

  media.addEventListener('change', onSystemChange)
  window.addEventListener('storage', onStorage)
  applyTheme(readPreference())

  return () => {
    listeners.delete(listener)
    media.removeEventListener('change', onSystemChange)
    window.removeEventListener('storage', onStorage)
  }
}
