import { useSyncExternalStore } from 'react'
import { readPreference, setPreference, subscribe } from './theme'

// The preference lives outside React (localStorage + system setting), so we
// subscribe to it with useSyncExternalStore instead of copying it into state.
export function useTheme() {
  const preference = useSyncExternalStore(subscribe, readPreference)
  return { preference, setPreference }
}
