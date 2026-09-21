import React, { useState } from 'react';
import { MaterialIcon } from './MaterialIcon';
import { publicConfig } from '../config/public';
import { copyText, isMethodEnabled } from '../lib/donate';
import { PAYMENT_METHODS } from '../types/donation';
import type { PaymentMethodId } from '../types/donation';

export interface PaymentMethodSelectorProps {
  selectedMethod: PaymentMethodId;
  onSelectMethod: (method: PaymentMethodId) => void;
}

export const PaymentMethodSelector: React.FC<PaymentMethodSelectorProps> = ({
  selectedMethod,
  onSelectMethod,
}) => {
  const [copied, setCopied] = useState(false);
  const selected = PAYMENT_METHODS.find((m) => m.id === selectedMethod);
  const cryptoLive = isMethodEnabled('crypto');

  const handleCopyAddress = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!publicConfig.cryptoAddress) return;
    const ok = await copyText(publicConfig.cryptoAddress);
    if (ok) {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2400);
    }
  };

  return (
    <div className="w-full flex flex-col gap-[var(--spacing-space-lg)]">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 items-stretch">
        {PAYMENT_METHODS.map((method) => {
          const enabled = isMethodEnabled(method.id);
          const isSelected = selectedMethod === method.id;

          return (
            <div
              key={method.id}
              role="button"
              tabIndex={enabled ? 0 : -1}
              aria-disabled={!enabled}
              onClick={() => {
                if (enabled) onSelectMethod(method.id);
              }}
              onKeyDown={(e) => {
                if (enabled && (e.key === 'Enter' || e.key === ' ')) {
                  e.preventDefault();
                  onSelectMethod(method.id);
                }
              }}
              className={`group relative p-4 sm:p-5 rounded-2xl transition-all duration-300 flex flex-col justify-between shadow-xl ${
                enabled ? 'cursor-pointer' : 'cursor-not-allowed opacity-55'
              } ${
                isSelected && enabled
                  ? 'ring-2 -translate-y-1 shadow-2xl'
                  : enabled
                    ? 'hover:-translate-y-1 hover:bg-[var(--color-surface-container)]'
                    : ''
              }`}
              style={{
                backgroundColor: 'var(--color-surface-container-low)',
                borderColor: isSelected && enabled ? method.accentColor : 'transparent',
                boxShadow:
                  isSelected && enabled
                    ? `0 8px 30px rgba(0, 0, 0, 0.4), 0 0 15px ${method.badgeBg}`
                    : undefined,
              }}
            >
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
                      backgroundColor: enabled ? method.badgeBg : 'var(--color-surface-container-high)',
                      color: enabled ? method.badgeColor : 'var(--color-on-surface-variant)',
                      fontFamily: 'var(--font-body)',
                      fontSize: 'var(--text-caption-code)',
                    }}
                  >
                    {enabled ? method.badge : 'Not configured'}
                  </span>
                </div>

                <h3
                  className="font-semibold mb-[var(--spacing-space-xxs)]"
                  style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: 'var(--text-headline-sm)',
                    color: isSelected && enabled ? method.accentColor : 'var(--color-on-surface)',
                  }}
                >
                  {method.name}
                </h3>

                <p
                  className="mb-[var(--spacing-space-sm)]"
                  style={{
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-caption-code)',
                    color: 'var(--color-on-surface-variant)',
                  }}
                >
                  {method.subtitle}
                </p>

                <p
                  className="leading-relaxed mb-[var(--spacing-space-md)]"
                  style={{
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-body-sm)',
                    color: 'var(--color-on-surface-variant)',
                  }}
                >
                  {enabled
                    ? method.description
                    : 'No public checkout URL or address is set for this rail yet. Cards stay disabled until one is published in client config.'}
                </p>
              </div>

              <button
                type="button"
                disabled={!enabled}
                className="w-full py-[var(--spacing-space-xs)] px-[var(--spacing-space-sm)] rounded-full font-semibold transition-all flex items-center justify-center gap-1.5"
                style={{
                  backgroundColor:
                    isSelected && enabled ? method.accentColor : 'var(--color-surface-container-high)',
                  color: isSelected && enabled ? '#000000' : 'var(--color-on-surface)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-md)',
                  cursor: enabled ? 'pointer' : 'not-allowed',
                }}
              >
                <span>
                  {!enabled ? 'Unavailable' : isSelected ? 'Method selected' : 'Choose method'}
                </span>
                <MaterialIcon
                  icon={
                    !enabled
                      ? 'block'
                      : isSelected
                        ? 'radio_button_checked'
                        : 'radio_button_unchecked'
                  }
                  className="text-[16px]"
                />
              </button>
            </div>
          );
        })}
      </div>

      <div
        className="p-4 sm:p-6 rounded-2xl border"
        style={{
          backgroundColor: 'var(--color-surface-container-low)',
          borderColor: 'var(--color-surface-container-high)',
        }}
      >
        {selectedMethod === 'crypto' && cryptoLive && (
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4">
            <div className="flex items-start gap-3 sm:gap-4">
              <div
                className="w-10 h-10 sm:w-12 sm:h-12 rounded-full flex items-center justify-center shrink-0"
                style={{ backgroundColor: 'rgba(255, 193, 7, 0.25)', color: 'var(--color-attention-yellow)' }}
              >
                <MaterialIcon icon="account_balance_wallet" className="text-[22px] sm:text-[24px]" />
              </div>
              <div className="flex flex-col">
                <h4
                  className="font-semibold text-base sm:text-lg"
                  style={{
                    fontFamily: 'var(--font-display)',
                    color: 'var(--color-on-surface)',
                  }}
                >
                  {publicConfig.cryptoNetwork}
                </h4>
                <p
                  className="text-xs sm:text-sm"
                  style={{
                    fontFamily: 'var(--font-body)',
                    color: 'var(--color-on-surface-variant)',
                  }}
                >
                  Copy the published receive address. This site cannot confirm the transfer.
                </p>
              </div>
            </div>
            <div className="flex flex-col xs:flex-row items-stretch xs:items-center gap-2 w-full sm:w-auto min-w-0">
              <span
                className="truncate font-mono text-xs px-3 py-1.5 rounded-full text-center xs:text-left"
                style={{
                  backgroundColor: 'var(--color-surface-container-high)',
                  color: 'var(--color-primary)',
                }}
              >
                {publicConfig.cryptoAddress}
              </span>
              <button
                type="button"
                onClick={handleCopyAddress}
                className="shrink-0 px-4 py-1.5 rounded-full font-semibold flex items-center justify-center gap-1 cursor-pointer transition-all active:scale-95"
                style={{
                  backgroundColor: copied ? 'var(--color-tertiary)' : 'var(--color-surface-container-highest)',
                  color: copied ? '#000' : 'var(--color-on-surface)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-md)',
                }}
              >
                <MaterialIcon icon={copied ? 'check' : 'content_copy'} className="text-[16px]" />
                <span>{copied ? 'Copied' : 'Copy'}</span>
              </button>
            </div>
          </div>
        )}

        {selectedMethod === 'crypto' && !cryptoLive && (
          <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
            No public crypto address is configured. Add one in <code>src/config/public.ts</code> when it exists.
          </p>
        )}

        {selectedMethod !== 'crypto' && selected && (
          <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
            {isMethodEnabled(selectedMethod)
              ? `Continue opens ${selected.name} in a new tab. Captionary does not process the payment.`
              : `A public ${selected.name} link is not configured yet. Copy the amount and come back when a checkout URL is published.`}
          </p>
        )}
      </div>
    </div>
  );
};
