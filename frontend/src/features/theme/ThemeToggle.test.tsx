import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { mockPrefersDark } from '../../test/mockMatchMedia'
import { THEME_STORAGE_KEY } from './theme'
import { ThemeToggle } from './ThemeToggle'

const html = document.documentElement

describe('ThemeToggle', () => {
  afterEach(() => {
    localStorage.clear()
    html.classList.remove('dark')
    vi.unstubAllGlobals()
  })

  it('follows the system preference by default', () => {
    mockPrefersDark(true)

    render(<ThemeToggle />)

    expect(screen.getByRole('radio', { name: 'Système' })).toBeChecked()
    expect(html).toHaveClass('dark')
  })

  it('switches to dark mode and remembers the choice', () => {
    mockPrefersDark(false)
    render(<ThemeToggle />)

    fireEvent.click(screen.getByRole('radio', { name: 'Sombre' }))

    expect(html).toHaveClass('dark')
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')
  })

  it('switches to light mode even when the system prefers dark', () => {
    mockPrefersDark(true)
    render(<ThemeToggle />)

    fireEvent.click(screen.getByRole('radio', { name: 'Clair' }))

    expect(html).not.toHaveClass('dark')
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('light')
  })

  it('restores the stored choice', () => {
    mockPrefersDark(false)
    localStorage.setItem(THEME_STORAGE_KEY, 'dark')

    render(<ThemeToggle />)

    expect(screen.getByRole('radio', { name: 'Sombre' })).toBeChecked()
    expect(html).toHaveClass('dark')
  })

  it('reacts to system changes while on "Système"', () => {
    const system = mockPrefersDark(false)
    render(<ThemeToggle />)

    act(() => system.setPrefersDark(true))

    expect(html).toHaveClass('dark')
  })

  it('forgets the stored choice when going back to "Système"', () => {
    mockPrefersDark(false)
    localStorage.setItem(THEME_STORAGE_KEY, 'dark')
    render(<ThemeToggle />)

    fireEvent.click(screen.getByRole('radio', { name: 'Système' }))

    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBeNull()
    expect(html).not.toHaveClass('dark')
  })
})
