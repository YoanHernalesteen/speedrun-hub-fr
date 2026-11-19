import { ThemeToggle } from './features/theme/ThemeToggle'

function App() {
  return (
    <div className="min-h-svh">
      <header className="border-b border-border">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3">
          <a
            href="/"
            className="font-display text-2xl font-extrabold tracking-tight uppercase"
          >
            Speedrun <span className="text-accent">Hub</span>
          </a>
          <ThemeToggle />
        </div>
      </header>
    </div>
  )
}

export default App
