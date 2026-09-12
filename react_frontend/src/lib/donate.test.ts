import { describe, expect, it } from 'vitest'
import { checkoutUrlFor, donationInstructions, isMethodEnabled } from '../lib/donate'

describe('donate helpers', () => {
  it('treats empty public URLs as disabled rails', () => {
    expect(isMethodEnabled('kofi')).toBe(false)
    expect(isMethodEnabled('bmc')).toBe(false)
    expect(isMethodEnabled('paynow')).toBe(false)
    expect(isMethodEnabled('crypto')).toBe(false)
    expect(checkoutUrlFor('kofi')).toBeUndefined()
  })

  it('includes a missing-link note in copyable instructions', () => {
    const text = donationInstructions(10, 'kofi')
    expect(text).toContain('$10 USD')
    expect(text).toContain('No public checkout URL is configured')
  })
})
