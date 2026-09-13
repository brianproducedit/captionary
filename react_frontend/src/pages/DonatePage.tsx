import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MaterialIcon } from '../components/MaterialIcon';
import { DonationAmountSelector } from '../components/DonationAmountSelector';
import { PaymentMethodSelector } from '../components/PaymentMethodSelector';
import { PRESET_TIERS, PAYMENT_METHODS } from '../types/donation';
import type { PaymentMethodId } from '../types/donation';
import { publicConfig } from '../config/public';
import {
  checkoutUrlFor,
  copyText,
  donationInstructions,
  isMethodEnabled,
} from '../lib/donate';

export const DonatePage: React.FC = () => {
  const navigate = useNavigate();

  const [selectedTier, setSelectedTier] = useState<string>('language');
  const [selectedAmount, setSelectedAmount] = useState<number>(10);
  const [customAmount, setCustomAmount] = useState<number>(25);
  const [giftMessage, setGiftMessage] = useState<string>('');
  const [selectedMethod, setSelectedMethod] = useState<PaymentMethodId>('kofi');
  const [online, setOnline] = useState(
    () => (typeof navigator === 'undefined' ? true : navigator.onLine),
  );
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const goOnline = () => setOnline(true);
    const goOffline = () => setOnline(false);
    window.addEventListener('online', goOnline);
    window.addEventListener('offline', goOffline);
    return () => {
      window.removeEventListener('online', goOnline);
      window.removeEventListener('offline', goOffline);
    };
  }, []);

  const handleSelectTier = (tierId: string, amount: number) => {
    setSelectedTier(tierId);
    setSelectedAmount(amount);
  };

  const handleCustomAmountChange = (amount: number) => {
    setCustomAmount(amount);
    if (selectedTier === 'custom') {
      setSelectedAmount(amount);
    }
  };

  const getTierDisplayName = (): string => {
    if (selectedTier === 'custom') return 'Custom Fuel Contribution';
    const found = PRESET_TIERS.find((t) => t.id === selectedTier);
    return found ? found.name : 'Language Champion';
  };

  const getMethodDisplayName = (): string => {
    const found = PAYMENT_METHODS.find((m) => m.id === selectedMethod);
    return found ? found.name : 'Ko-fi';
  };

  const methodEnabled = isMethodEnabled(selectedMethod);
  const checkoutUrl = checkoutUrlFor(selectedMethod);
  const canContinue =
    online && methodEnabled && (Boolean(checkoutUrl) || selectedMethod === 'crypto');

  const handleCopyInstructions = async () => {
    const ok = await copyText(donationInstructions(selectedAmount, selectedMethod));
    if (ok) {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2400);
    }
  };

  const goPending = () => {
    navigate('/payment-confirmation', {
      state: {
        amount: selectedAmount,
        tierName: getTierDisplayName(),
        paymentMethod: selectedMethod,
        paymentMethodTitle: getMethodDisplayName(),
        message: giftMessage,
        pendingExternal: true,
        instructions: donationInstructions(selectedAmount, selectedMethod),
      },
    });
  };

  const handleOpenCheckout = async () => {
    if (!canContinue) return;
    if (selectedMethod === 'crypto') {
      if (publicConfig.cryptoAddress) {
        await copyText(publicConfig.cryptoAddress);
      }
      goPending();
      return;
    }
    if (!checkoutUrl) return;
    window.open(checkoutUrl, '_blank', 'noopener,noreferrer');
    goPending();
  };

  return (
    <div
      className="max-w-7xl mx-auto pb-[var(--spacing-space-xl)] flex flex-col relative px-4 md:px-8 xl:px-12"
      data-donate-url={publicConfig.donateWebUrl}
    >
      <div className="flex flex-col w-full">
        <div className="relative w-full overflow-hidden pb-[var(--spacing-space-3xl)]">
          <div
            className="absolute top-0 left-1/2 -translate-x-1/2 w-[720px] h-[380px] blur-3xl pointer-events-none -z-10"
            style={{ backgroundImage: 'linear-gradient(to bottom, rgba(33, 150, 243, 0.15), rgba(249, 171, 255, 0.1), transparent)' }}
          ></div>
          <div
            className="absolute -top-12 left-10 w-96 h-96 rounded-full blur-[100px] pointer-events-none -z-10"
            style={{ backgroundColor: 'rgba(33, 150, 243, 0.1)' }}
          ></div>
          <div
            className="absolute top-20 right-10 w-80 h-80 rounded-full blur-[100px] pointer-events-none -z-10"
            style={{ backgroundColor: 'rgba(249, 171, 255, 0.1)' }}
          ></div>

          {/* Hero Section */}
          <section className="flex flex-col items-center text-center pb-[var(--spacing-space-2xl)] max-w-4xl mx-auto pt-8">
            <div className="mb-[var(--spacing-space-lg)] relative flex items-center justify-center">
              <div
                className="absolute inset-0 rounded-full blur-xl opacity-40 animate-pulse"
                style={{ backgroundImage: 'linear-gradient(to top right, var(--color-primary-container), var(--color-secondary))' }}
              ></div>
              <div
                className="relative p-[var(--spacing-space-xs)] rounded-full shadow-[0_4px_24px_rgba(33,150,243,0.35)]"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}
              >
                <img
                  alt="Captionary Open-Source Foundation Emblem"
                  className="w-20 h-20 md:w-24 md:h-24 rounded-full object-cover"
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuABENpPUIXPkO4lnSGrJU05nCximKB9kEW7pOOMQfgK2gAUrISb0UxrqwSA-vSTLPVKbFk5sbril5e8I8X3NMupNT_iczaq3ca6NxhiTxC7syftruEOThHdJpbJx_vT4QRjnUsDp8XN8H_FM9dgP9ZanhfS7Aq7GusGxaO8gBIsc2Sz9JSXm0dg7X9qDsmEJaWBUpXuMOfv3GLDiNL4dN3qp-_t2qTRgZG-2XB0LMrGHRRAFBd_fVmuDFvswISP90w-kw"
                />
              </div>
            </div>

            <div
              className="inline-flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full shadow-sm mb-[var(--spacing-space-md)]"
              style={{ backgroundColor: 'var(--color-surface-container-high)' }}
            >
              <span className="w-2 h-2 rounded-full shadow-[0_0_8px_#4CAF50] animate-ping" style={{ backgroundColor: 'var(--color-tertiary)' }}></span>
              <span
                className="uppercase tracking-widest font-semibold"
                style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-tertiary)' }}
              >
                Open-Source & Serverless Initiative
              </span>
            </div>

            <h1
              className="tracking-tight max-w-3xl mb-[var(--spacing-space-sm)] font-bold leading-tight text-[length:var(--text-display-lg-mobile)] md:text-[length:var(--text-display-lg)]"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--color-on-surface)' }}
            >
              Donate Independent{' '}
              <span
                className="bg-clip-text text-transparent"
                style={{ backgroundImage: 'linear-gradient(to right, var(--color-primary), var(--color-secondary), var(--color-secondary-fixed-dim))' }}
              >
                Open-Source Speech
              </span>
            </h1>

            <p
              className="max-w-2xl mb-[var(--spacing-space-xl)] leading-relaxed"
              style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-lg)', color: 'var(--color-on-surface-variant)' }}
            >
              Captionary is 100% free, serverless, and ad-light. Help keep regional African language speech-to-text models accessible,
              privacy-respecting, and uncensored for creators worldwide.
            </p>

            <div
              className="inline-flex items-center gap-[var(--spacing-space-sm)] px-[var(--spacing-space-lg)] py-[var(--spacing-space-xs)] rounded-full shadow-md"
              style={{ backgroundColor: 'var(--color-surface-container-lowest)' }}
            >
              <div className="flex -space-x-2 overflow-hidden">
                <span
                  className="inline-flex items-center justify-center w-7 h-7 rounded-full font-bold"
                  style={{
                    backgroundColor: 'var(--color-primary-container)',
                    color: 'var(--color-on-primary)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-caption-code)'
                  }}
                >
                  ZW
                </span>
                <span
                  className="inline-flex items-center justify-center w-7 h-7 rounded-full font-bold"
                  style={{
                    backgroundColor: 'var(--color-secondary-container)',
                    color: 'var(--color-on-secondary)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-caption-code)'
                  }}
                >
                  ZA
                </span>
                <span
                  className="inline-flex items-center justify-center w-7 h-7 rounded-full font-bold"
                  style={{
                    backgroundColor: 'var(--color-tertiary-container)',
                    color: 'var(--color-on-tertiary)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-caption-code)'
                  }}
                >
                  KE
                </span>
              </div>
              <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-md)', color: 'var(--color-on-surface)' }}>
                Independent creators & researchers keeping regional speech free
              </span>
              <MaterialIcon icon="verified" className="text-[18px]" style={{ color: 'var(--color-tertiary)' }} />
            </div>
          </section>

          {/* STEP 01: Fuel Tier Selection */}
          <section className="w-full mb-[var(--spacing-space-3xl)]">
            <div className="flex items-center justify-between mb-[var(--spacing-space-lg)]">
              <div>
                <span
                  className="uppercase tracking-wider"
                  style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}
                >
                  Step 01
                </span>
                <h2
                  className="tracking-tight font-semibold"
                  style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-md)', color: 'var(--color-on-surface)' }}
                >
                  Select Fuel Tier
                </h2>
              </div>
              <div
                className="hidden sm:flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full"
                style={{
                  backgroundColor: 'var(--color-surface-container-low)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-caption-code)',
                  color: 'var(--color-on-surface-variant)'
                }}
              >
                <span className="w-2 h-2 rounded-full" style={{ backgroundColor: 'var(--color-tertiary)' }}></span>
                Static page • payments happen off-site
              </div>
            </div>

            <DonationAmountSelector
              selectedTier={selectedTier}
              selectedAmount={selectedAmount}
              customAmount={customAmount}
              giftMessage={giftMessage}
              onSelectTier={handleSelectTier}
              onCustomAmountChange={handleCustomAmountChange}
              onGiftMessageChange={setGiftMessage}
            />
          </section>

          {/* STEP 02: Payment Method Selector */}
          <section className="w-full mb-[var(--spacing-space-3xl)]">
            <div className="mb-[var(--spacing-space-xl)]">
              <span
                className="uppercase tracking-wider"
                style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}
              >
                Step 02
              </span>
              <h2
                className="tracking-tight font-semibold"
                style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-xl)', color: 'var(--color-on-surface)' }}
              >
                Select Secure Payment Method
              </h2>
              <p
                className="mt-[var(--spacing-space-xxs)]"
                style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}
              >
                Public checkout links only. Empty rails stay disabled until a URL or address is published.
              </p>
            </div>

            <PaymentMethodSelector
              selectedMethod={selectedMethod}
              onSelectMethod={setSelectedMethod}
            />
          </section>

          {/* STEP 03: Final Contribution Confirmation Action Box */}
          <section className="w-full mb-[var(--spacing-space-3xl)]">
            <div
              className="p-[var(--spacing-space-xl)] rounded-2xl shadow-2xl relative overflow-hidden border flex flex-col lg:flex-row items-center justify-between gap-[var(--spacing-space-xl)]"
              style={{
                backgroundColor: 'var(--color-surface-container-low)',
                borderColor: 'var(--color-surface-container-high)'
              }}
            >
              <div
                className="absolute inset-0 pointer-events-none"
                style={{ backgroundImage: 'linear-gradient(to right, rgba(33, 150, 243, 0.08), transparent, rgba(134, 3, 156, 0.08))' }}
              ></div>

              {/* Left Side: Summary info */}
              <div className="flex flex-col gap-2 relative z-10 w-full lg:w-auto">
                <div className="flex flex-wrap items-center gap-2">
                  <span
                    className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider"
                    style={{ backgroundColor: 'var(--color-primary-container)', color: 'var(--color-on-primary)' }}
                  >
                    External checkout
                  </span>
                  {!online && (
                    <span
                      data-testid="offline-banner"
                      className="text-xs font-medium"
                      style={{ color: 'var(--color-attention-yellow)' }}
                    >
                      You appear offline. Copy instructions and open checkout when you have a connection.
                    </span>
                  )}
                  {online && !methodEnabled && (
                    <span className="text-xs" style={{ color: 'var(--color-on-surface-variant)' }}>
                      No public checkout link is configured for this rail yet.
                    </span>
                  )}
                </div>

                <div className="flex items-baseline gap-3">
                  <span className="text-4xl font-extrabold" style={{ fontFamily: 'var(--font-display)', color: 'var(--color-on-surface)' }}>
                    ${selectedAmount}.00 USD
                  </span>
                  <span className="text-sm font-semibold" style={{ color: 'var(--color-primary)' }}>
                    {getTierDisplayName()}
                  </span>
                </div>

                <p className="text-xs max-w-xl" style={{ color: 'var(--color-on-surface-variant)' }}>
                  Selected rail: <strong style={{ color: 'var(--color-on-surface)' }}>{getMethodDisplayName()}</strong>
                  {giftMessage ? ` • Shout-out note attached` : ''}
                </p>
              </div>

              {/* Right Side: Big CTA Button */}
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 relative z-10 w-full lg:w-auto min-w-0">
                <button
                  type="button"
                  id="copy-instructions-btn"
                  onClick={handleCopyInstructions}
                  className="w-full sm:w-auto px-6 py-3 rounded-full font-semibold flex items-center justify-center gap-2 cursor-pointer shrink-0"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: 'var(--color-on-surface)',
                    fontFamily: 'var(--font-body)',
                    fontSize: 'var(--text-label-lg)',
                  }}
                >
                  <MaterialIcon icon={copied ? 'check' : 'content_copy'} className="text-[18px]" />
                  <span>{copied ? 'Copied' : 'Copy instructions'}</span>
                </button>
                <button
                  type="button"
                  id="confirm-donation-btn"
                  onClick={handleOpenCheckout}
                  disabled={!canContinue}
                  className="w-full sm:w-auto px-8 py-4 rounded-full font-bold shadow-[0_4px_24px_rgba(33,150,243,0.4)] transition-all duration-200 flex items-center justify-center gap-3 shrink-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                  style={{
                    backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary))',
                    color: 'var(--color-on-primary)',
                    fontFamily: 'var(--font-display)',
                    fontSize: 'var(--text-headline-sm)',
                    cursor: canContinue ? 'pointer' : 'not-allowed',
                  }}
                >
                  <MaterialIcon icon="open_in_new" className="text-[22px]" />
                  <span>Open external checkout • ${selectedAmount}.00</span>
                </button>
              </div>
            </div>
          </section>

        </div>
      </div>
    </div>
  );
};
