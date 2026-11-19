import { vi } from 'vitest'

// jsdom does not implement matchMedia: this fake lets tests set and change
// the system color scheme preference.
export function mockPrefersDark(initial: boolean) {
  let matches = initial
  const listeners = new Set<(event: MediaQueryListEvent) => void>()

  vi.stubGlobal(
    'matchMedia',
    vi.fn((query: string) => ({
      get matches() {
        return query === '(prefers-color-scheme: dark)' && matches
      },
      media: query,
      addEventListener: (
        _type: 'change',
        listener: (event: MediaQueryListEvent) => void,
      ) => listeners.add(listener),
      removeEventListener: (
        _type: 'change',
        listener: (event: MediaQueryListEvent) => void,
      ) => listeners.delete(listener),
    })),
  )

  return {
    setPrefersDark(value: boolean) {
      matches = value
      listeners.forEach((listener) =>
        listener({ matches: value } as MediaQueryListEvent),
      )
    },
  }
}
