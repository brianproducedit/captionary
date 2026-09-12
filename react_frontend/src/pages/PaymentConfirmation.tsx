import React, { useState } from 'react';
import { useLocation, Link } from 'react-router-dom';
import { MaterialIcon } from '../components/MaterialIcon';
import captionaryLogo from '../assets/images/captionary_logo.png';
import { copyText } from '../lib/donate';
import type { PaymentLocationState } from '../types/donation';

export const PaymentConfirmation: React.FC = () => {
  const location = useLocation();
  const state = (location.state as PaymentLocationState) || {};

  const amount = state.amount ?? 10;
  const tierName = state.tierName ?? 'Supporter';
  const paymentMethodTitle = state.paymentMethodTitle ?? 'External checkout';
  const message = state.message;
  const instructions = state.instructions;

  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    const text = instructions ?? `Captionary donation: $${amount} USD via ${paymentMethodTitle}`;
    const ok = await copyText(text);
    if (ok) {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div
      className="max-w-7xl mx-auto pb-[var(--spacing-space-xl)] flex flex-col"
      style={{
        paddingLeft: 'var(--spacing-margin-mobile)',
        paddingRight: 'var(--spacing-margin-mobile)',
      }}
    >
      <div className="relative max-w-4xl mx-auto w-full pt-8 pb-[var(--spacing-space-xl)]">
        <div
          className="relative rounded-lg shadow-2xl overflow-hidden p-[var(--spacing-space-md)] md:p-[var(--spacing-space-2xl)]"
          style={{ backgroundColor: '#141414' }}
        >
          <div className="flex flex-col items-center text-center space-y-[var(--spacing-space-md)]">
            <div
              className="relative w-20 h-20 rounded-full flex items-center justify-center"
              style={{ backgroundColor: '#1c1b1b', color: 'var(--color-attention-yellow)' }}
            >
              <MaterialIcon icon="schedule" className="text-[44px]" />
            </div>
            <div
              className="inline-flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full tracking-wide uppercase"
              style={{
                backgroundColor: 'rgba(255, 193, 7, 0.15)',
                color: 'var(--color-attention-yellow)',
                fontFamily: 'var(--font-body)',
                fontSize: 'var(--text-caption-code)',
              }}
            >
              Pending external payment
            </div>
            <h1
              className="tracking-tight"
              style={{
                fontFamily: 'var(--font-display)',
                fontSize: 'var(--text-headline-xl)',
                color: 'var(--color-on-surface)',
              }}
            >
              You left to pay externally
            </h1>
            <p
              className="leading-relaxed max-w-2xl"
              style={{
                fontFamily: 'var(--font-body)',
                fontSize: 'var(--text-body-lg)',
                color: 'var(--color-on-surface-variant)',
              }}
            >
              This static site cannot confirm, verify, or settle a donation. If you completed checkout in another tab,
              thank you — we will not show a fabricated receipt here.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-12 gap-[var(--spacing-space-lg)] mt-[var(--spacing-space-2xl)]">
            <div
              className="md:col-span-7 rounded-DEFAULT p-[var(--spacing-space-lg)]"
              style={{ backgroundColor: '#1c1b1b' }}
            >
              <div className="flex items-center justify-between mb-[var(--spacing-space-md)]">
                <span
                  style={{
                    fontFamily: 'var(--font-display)',
                    fontSize: 'var(--text-headline-sm)',
                    color: 'var(--color-on-surface)',
                  }}
                >
                  What you selected
                </span>
                <span
                  className="px-[var(--spacing-space-xs)] py-[var(--spacing-space-xxs)] rounded-full"
                  style={{
                    backgroundColor: 'var(--color-surface-container-highest)',
                    color: 'var(--color-attention-yellow)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-caption-code)',
                  }}
                >
                  Not settled here
                </span>
              </div>
              <div className="space-y-[var(--spacing-space-md)]" style={{ fontFamily: 'var(--font-body)' }}>
                <div className="flex items-center justify-between">
                  <span style={{ color: 'var(--color-on-surface-variant)' }}>Intended amount</span>
                  <span className="font-semibold" style={{ color: 'var(--color-on-surface)' }}>
                    ${amount.toFixed(2)} · {tierName}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span style={{ color: 'var(--color-on-surface-variant)' }}>Method</span>
                  <span style={{ color: 'var(--color-on-surface)' }}>{paymentMethodTitle}</span>
                </div>
                {message ? (
                  <p className="italic text-sm" style={{ color: 'var(--color-on-surface-variant)' }}>
                    Note: {message}
                  </p>
                ) : null}
                <button
                  type="button"
                  onClick={handleCopy}
                  className="px-4 py-2 rounded-full cursor-pointer"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: 'var(--color-on-surface)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-label-md)',
                  }}
                >
                  {copied ? 'Copied' : 'Copy instructions again'}
                </button>
              </div>
            </div>

            <div
              className="md:col-span-5 rounded-DEFAULT p-[var(--spacing-space-lg)]"
              style={{ backgroundColor: '#1c1b1b' }}
            >
              <span
                className="font-semibold uppercase"
                style={{
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-lg)',
                  color: 'var(--color-on-surface)',
                }}
              >
                Planning estimate only
              </span>
              <p
                className="mt-[var(--spacing-space-sm)] leading-relaxed"
                style={{
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-body-sm)',
                  color: 'var(--color-on-surface-variant)',
                }}
              >
                We do not claim that ${amount} helped a measured number of creators. Any impact depends on how funds
                are actually used after an external checkout.
              </p>
            </div>
          </div>

          <div className="mt-[var(--spacing-space-xl)] flex flex-col md:flex-row items-center justify-center gap-[var(--spacing-space-md)]">
            <Link
              to="/donate"
              className="w-full md:w-auto px-[var(--spacing-space-xl)] py-[var(--spacing-space-sm)] rounded-full font-semibold flex items-center justify-center gap-[var(--spacing-space-xs)]"
              style={{
                backgroundImage: 'linear-gradient(to right, var(--color-primary-container), #673AB7)',
                color: 'var(--color-on-primary)',
                fontFamily: 'var(--font-body)',
                fontSize: 'var(--text-label-lg)',
              }}
            >
              Back to donate
            </Link>
            <button
              type="button"
              className="w-full md:w-auto px-[var(--spacing-space-lg)] py-[var(--spacing-space-sm)] rounded-full cursor-pointer"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                color: 'var(--color-on-surface)',
                fontFamily: 'var(--font-body)',
                fontSize: 'var(--text-label-lg)',
              }}
              onClick={() => window.print()}
            >
              Print this page
            </button>
          </div>

          <div className="mt-[var(--spacing-space-2xl)] flex flex-col items-center gap-[var(--spacing-space-xs)]">
            <img alt="Captionary Logo" className="w-7 h-7 rounded-full object-cover" src={captionaryLogo} />
            <span style={{ fontFamily: 'var(--font-display)', color: 'var(--color-on-surface)' }}>Captionary</span>
          </div>
        </div>
      </div>
    </div>
  );
};
