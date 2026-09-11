import React, { useState } from 'react';
import { MaterialIcon } from './MaterialIcon';
import { PAYMENT_METHODS } from '../types/donation';
import type { PaymentMethodId } from '../types/donation';

export interface PaymentMethodSelectorProps {
  selectedMethod: PaymentMethodId;
  onSelectMethod: (method: PaymentMethodId) => void;
  ecoCashPhone: string;
  onEcoCashPhoneChange: (phone: string) => void;
}

export const PaymentMethodSelector: React.FC<PaymentMethodSelectorProps> = ({
  selectedMethod,
  onSelectMethod,
  ecoCashPhone,
  onEcoCashPhoneChange
}) => {
  const [walletCopied, setWalletCopied] = useState(false);
  const walletAddress = '0x71CB4e29A88fF7094A0E189C67B9E9B49F98AA51';

  const handleCopyWallet = (e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(walletAddress).then(() => {
      setWalletCopied(true);
      setTimeout(() => setWalletCopied(false), 2400);
    });
  };

  return (
    <div className="w-full flex flex-col gap-[var(--spacing-space-lg)]">
      {/* 2x2 or 4-col Responsive Grid of Selectable Methods */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-[var(--spacing-gutter-desktop)] items-stretch">
        {PAYMENT_METHODS.map((method) => {
          const isSelected = selectedMethod === method.id;

          return (
            <div
              key={method.id}
              onClick={() => onSelectMethod(method.id)}
              className={`group relative cursor-pointer p-[var(--spacing-space-lg)] rounded-lg transition-all duration-300 flex flex-col justify-between shadow-xl ${
                isSelected
                  ? 'ring-2 -translate-y-1 shadow-2xl'
                  : 'hover:-translate-y-1 hover:bg-[var(--color-surface-container)]'
              }`}
              style={{
                backgroundColor: 'var(--color-surface-container-low)',
                borderColor: isSelected ? method.accentColor : 'transparent',
                boxShadow: isSelected ? `0 8px 30px rgba(0, 0, 0, 0.4), 0 0 15px ${method.badgeBg}` : undefined
              }}
            >
              {/* Top Row: Icon + Badge */}
              <div>
                <div className="flex items-center justify-between mb-[var(--spacing-space-md)]">
                  <div
                    className="w-12 h-12 rounded-full flex items-center justify-center transition-transform group-hover:scale-110"
                    style={{ backgroundColor: method.badgeBg, color: method.accentColor }}
                  >
                    <MaterialIcon icon={method.icon} className="text-[24px]" />
                  </div>

                  <span
                    className="px-[var(--spacing-space-xs)] py-[var(--spacing-space-xxs)] rounded-full font-semibold uppercase tracking-wider"
                    style={{
                      backgroundColor: method.badgeBg,
                      color: method.badgeColor,
                      fontFamily: 'var(--font-body)',
                      fontSize: 'var(--text-caption-code)'
                    }}
                  >
                    {method.badge}
                  </span>
                </div>

                <h3
                  className="font-semibold mb-[var(--spacing-space-xxs)]"
                  style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: 'var(--text-headline-sm)',
                    color: isSelected ? method.accentColor : 'var(--color-on-surface)'
                  }}
                >
                  {method.name}
                </h3>

                <p
                  className="mb-[var(--spacing-space-sm)]"
                  style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}
                >
                  {method.subtitle}
                </p>

                <p
                  className="leading-relaxed mb-[var(--spacing-space-md)]"
                  style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}
                >
                  {method.description}
                </p>

                {/* Micro Feature Bullet Points */}
                <ul className="flex flex-col gap-1 mb-[var(--spacing-space-md)]">
                  {method.features.map((feat, idx) => (
                    <li key={idx} className="flex items-center gap-1.5" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                      <MaterialIcon icon="check" className="text-[14px]" style={{ color: method.accentColor }} />
                      <span>{feat}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Selection Indicator Pill / Button */}
              <button
                type="button"
                className="w-full py-[var(--spacing-space-xs)] px-[var(--spacing-space-sm)] rounded-full font-semibold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
                style={{
                  backgroundColor: isSelected ? method.accentColor : 'var(--color-surface-container-high)',
                  color: isSelected ? '#000000' : 'var(--color-on-surface)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-md)'
                }}
              >
                <span>{isSelected ? 'Method Selected' : 'Choose Method'}</span>
                <MaterialIcon icon={isSelected ? 'radio_button_checked' : 'radio_button_unchecked'} className="text-[16px]" />
              </button>
            </div>
          );
        })}
      </div>

      {/* Dynamic Detail Card for the Currently Selected Payment Method */}
      <div
        className="p-[var(--spacing-space-lg)] rounded-DEFAULT border transition-all duration-300"
        style={{
          backgroundColor: 'var(--color-surface-container-low)',
          borderColor: 'var(--color-surface-container-high)'
        }}
      >
        {selectedMethod === 'ecocash' && (
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-[var(--spacing-space-md)]">
            <div className="flex items-start gap-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: 'rgba(66, 165, 71, 0.25)', color: 'var(--color-tertiary)' }}
              >
                <MaterialIcon icon="phone_android" className="text-[24px]" />
              </div>
              <div className="flex flex-col">
                <h4 className="font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
                  EcoCash Mobile USSD Checkout
                </h4>
                <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
                  Enter your EcoCash registered subscriber number. We will push an instant *151# authorization pin prompt directly to your handset.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-[var(--spacing-space-xs)] w-full md:w-auto">
              <div className="relative flex items-center w-full md:w-72">
                <span className="absolute left-3 font-mono font-bold" style={{ color: 'var(--color-tertiary)', fontSize: 'var(--text-body-sm)' }}>
                  +263
                </span>
                <input
                  type="tel"
                  placeholder="77 123 4567"
                  value={ecoCashPhone}
                  onChange={(e) => onEcoCashPhoneChange(e.target.value)}
                  className="w-full pl-16 pr-3 py-2 rounded-full font-mono transition-all focus:outline-none focus:ring-1"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: 'var(--color-on-surface)',
                    fontSize: 'var(--text-body-sm)',
                    borderColor: 'var(--color-tertiary)'
                  }}
                />
              </div>
            </div>
          </div>
        )}

        {selectedMethod === 'innbucks' && (
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-[var(--spacing-space-md)]">
            <div className="flex items-start gap-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: 'rgba(134, 3, 156, 0.25)', color: 'var(--color-secondary)' }}
              >
                <MaterialIcon icon="qr_code_2" className="text-[24px]" />
              </div>
              <div className="flex flex-col">
                <h4 className="font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
                  InnBucks App & Voucher
                </h4>
                <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
                  Confirming will generate your dynamic invoice QR code or a one-time 6-digit payment voucher for instant settlement in the InnBucks app.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 px-3 py-1.5 rounded-full" style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-secondary)' }}>
              <MaterialIcon icon="verified" className="text-[18px]" />
              <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)' }}>Instant QR & Voucher Generation Ready</span>
            </div>
          </div>
        )}

        {selectedMethod === 'card' && (
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-[var(--spacing-space-md)]">
            <div className="flex items-start gap-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: 'rgba(33, 150, 243, 0.25)', color: 'var(--color-primary)' }}
              >
                <MaterialIcon icon="lock" className="text-[24px]" />
              </div>
              <div className="flex flex-col">
                <h4 className="font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
                  Global Credit & Debit Card Checkout
                </h4>
                <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
                  Protected by 256-bit encryption. Supports Apple Pay, Google Pay, Visa, Mastercard, and American Express.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <span className="px-3 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-on-surface)' }}>
                Apple Pay
              </span>
              <span className="px-3 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-on-surface)' }}>
                Google Pay
              </span>
              <span className="px-3 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-primary)' }}>
                Stripe / 3DSecure
              </span>
            </div>
          </div>
        )}

        {selectedMethod === 'crypto' && (
          <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-[var(--spacing-space-md)]">
            <div className="flex items-start gap-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: 'rgba(255, 193, 7, 0.25)', color: 'var(--color-attention-yellow)' }}
              >
                <MaterialIcon icon="account_balance_wallet" className="text-[24px]" />
              </div>
              <div className="flex flex-col">
                <h4 className="font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
                  EVM Multi-Sig Compute Vault
                </h4>
                <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
                  Accepts USDT, USDC, and POL on Polygon PoS. Direct decentralized smart contract with zero intermediary fees.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 w-full lg:w-auto">
              <span className="truncate font-mono text-xs px-3 py-1.5 rounded-full" style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-primary)' }}>
                {walletAddress}
              </span>
              <button
                type="button"
                onClick={handleCopyWallet}
                className="px-3 py-1.5 rounded-full font-semibold flex items-center gap-1 cursor-pointer transition-colors hover:bg-[var(--color-surface-bright)]"
                style={{
                  backgroundColor: walletCopied ? 'var(--color-tertiary)' : 'var(--color-surface-container-highest)',
                  color: walletCopied ? '#000' : 'var(--color-on-surface)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-md)'
                }}
              >
                <MaterialIcon icon={walletCopied ? 'check' : 'content_copy'} className="text-[16px]" />
                <span>{walletCopied ? 'Copied' : 'Copy'}</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
