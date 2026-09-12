import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import { useState } from 'react'
import App from '../App'
import { DonationAmountSelector } from '../components/DonationAmountSelector'
import { PaymentConfirmation } from '../pages/PaymentConfirmation'

afterEach(() => {
  cleanup()
})

function AmountHarness() {
  const [tier, setTier] = useState('language')
  const [amount, setAmount] = useState(10)
  const [custom, setCustom] = useState(25)
  const [message, setMessage] = useState('')
  return (
    <DonationAmountSelector
      selectedTier={tier}
      selectedAmount={amount}
      customAmount={custom}
      giftMessage={message}
      onSelectTier={(id, value) => {
        setTier(id)
        setAmount(value)
      }}
      onCustomAmountChange={setCustom}
      onGiftMessageChange={setMessage}
    />
  )
}

describe('donation portal', () => {
  it('selects a preset amount', () => {
    render(<AmountHarness />)
    fireEvent.click(screen.getByRole('button', { name: '$3' }))
    expect(screen.getByRole('button', { name: /Selected • \$3/i })).toBeInTheDocument()
  })

  it('redirects /support to /donate', () => {
    render(
      <MemoryRouter initialEntries={['/support']}>
        <App />
      </MemoryRouter>,
    )
    expect(screen.getByText(/Select Fuel Tier/i)).toBeInTheDocument()
    expect(screen.queryByText(/Payment authorized/i)).not.toBeInTheDocument()
  })

  it('shows an offline banner and never claims payment succeeded', () => {
    vi.stubGlobal('navigator', {
      ...navigator,
      onLine: false,
      clipboard: { writeText: vi.fn().mockResolvedValue(undefined) },
    })
    render(
      <MemoryRouter initialEntries={['/donate']}>
        <App />
      </MemoryRouter>,
    )
    expect(screen.getByTestId('offline-banner')).toBeInTheDocument()
    expect(screen.queryByText(/Payment authorized! Generating receipt/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/Payment Confirmed & Verified/i)).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Open external checkout/i })).toBeDisabled()
    vi.unstubAllGlobals()
  })

  it('confirmation copy is pending, not settled', () => {
    render(
      <MemoryRouter
        initialEntries={[
          {
            pathname: '/payment-confirmation',
            state: {
              amount: 10,
              tierName: 'Language Champion',
              paymentMethodTitle: 'Ko-fi',
              pendingExternal: true,
            },
          },
        ]}
      >
        <PaymentConfirmation />
      </MemoryRouter>,
    )
    expect(screen.getByText(/You left to pay externally/i)).toBeInTheDocument()
    expect(screen.queryByText('Settled')).not.toBeInTheDocument()
    expect(screen.queryByText(/Payment Confirmed & Verified/i)).not.toBeInTheDocument()
    expect(screen.getByText(/Planning estimate only/i)).toBeInTheDocument()
  })
})
