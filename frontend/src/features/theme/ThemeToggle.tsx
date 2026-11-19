import type { ThemePreference } from './theme'
import { useTheme } from './useTheme'

const OPTIONS: { value: ThemePreference; label: string }[] = [
  { value: 'system', label: 'Système' },
  { value: 'light', label: 'Clair' },
  { value: 'dark', label: 'Sombre' },
]

export function ThemeToggle() {
  const { preference, setPreference } = useTheme()

  return (
    <fieldset className="flex rounded-full border border-border p-0.5 text-xs font-medium">
      <legend className="sr-only">Thème</legend>
      {OPTIONS.map((option) => (
        <label
          key={option.value}
          className="cursor-pointer rounded-full px-3 py-1 text-muted transition-colors hover:text-fg has-checked:bg-accent has-checked:text-on-accent has-focus-visible:outline-2 has-focus-visible:outline-accent"
        >
          <input
            type="radio"
            name="theme"
            value={option.value}
            checked={preference === option.value}
            onChange={() => setPreference(option.value)}
            className="sr-only"
          />
          {option.label}
        </label>
      ))}
    </fieldset>
  )
}
