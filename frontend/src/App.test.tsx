import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import { mockPrefersDark } from './test/mockMatchMedia'

describe('App', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders the site header with the theme toggle', () => {
    mockPrefersDark(false)

    render(<App />)

    expect(
      screen.getByRole('link', { name: 'Speedrun Hub' }),
    ).toBeInTheDocument()
    expect(screen.getByRole('group', { name: 'Thème' })).toBeInTheDocument()
  })
})
