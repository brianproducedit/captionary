import React from 'react';
import { MaterialIcon } from './MaterialIcon';
import { PRESET_TIERS } from '../types/donation';

export interface DonationAmountSelectorProps {
  selectedTier: string;
  selectedAmount: number;
  customAmount: number;
  giftMessage: string;
  onSelectTier: (tierId: string, amount: number) => void;
  onCustomAmountChange: (amount: number) => void;
  onGiftMessageChange: (msg: string) => void;
}

export const DonationAmountSelector: React.FC<DonationAmountSelectorProps> = ({
  selectedTier,
  selectedAmount,
  customAmount,
  giftMessage,
  onSelectTier,
  onCustomAmountChange,
  onGiftMessageChange
}) => {
  const quickAmounts = [3, 5, 10, 25, 50];

  const handleQuickAmountClick = (amt: number) => {
    const matchedTier = PRESET_TIERS.find(t => t.amount === amt);
    if (matchedTier) {
      onSelectTier(matchedTier.id, matchedTier.amount);
    } else {
      onCustomAmountChange(amt);
      onSelectTier('custom', amt);
    }
  };

  return (
    <div className="w-full flex flex-col gap-[var(--spacing-space-xl)]">
      {/* Quick Preset Amount Pill Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-[var(--spacing-space-sm)] p-[var(--spacing-space-sm)] rounded-DEFAULT"
           style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
        <div className="flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-xs)]">
          <MaterialIcon icon="tune" className="text-[20px]" style={{ color: 'var(--color-primary)' }} />
          <span className="font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-md)', color: 'var(--color-on-surface)' }}>
            Quick Amount Select:
          </span>
        </div>

        <div className="flex flex-wrap items-center gap-[var(--spacing-space-xs)]">
          {quickAmounts.map((amt) => {
            const isSelected = selectedAmount === amt && selectedTier !== 'custom';
            return (
              <button
                key={amt}
                type="button"
                onClick={() => handleQuickAmountClick(amt)}
                className={`px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full font-bold transition-all duration-200 cursor-pointer flex items-center gap-1 ${
                  isSelected
                    ? 'shadow-[0_0_16px_rgba(33,150,243,0.45)] scale-105'
                    : 'hover:bg-[var(--color-surface-bright)]'
                }`}
                style={{
                  backgroundColor: isSelected ? 'var(--color-primary-container)' : 'var(--color-surface-container-high)',
                  color: isSelected ? 'var(--color-on-primary)' : 'var(--color-on-surface)',
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--text-label-lg)'
                }}
              >
                <span>${amt}</span>
                {isSelected && <MaterialIcon icon="check" className="text-[14px]" />}
              </button>
            );
          })}

          <button
            type="button"
            onClick={() => onSelectTier('custom', customAmount)}
            className={`px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full font-semibold transition-all duration-200 cursor-pointer flex items-center gap-1 ${
              selectedTier === 'custom'
                ? 'shadow-[0_0_16px_rgba(134,3,156,0.45)] scale-105'
                : 'hover:bg-[var(--color-surface-bright)]'
            }`}
            style={{
              backgroundColor: selectedTier === 'custom' ? 'var(--color-secondary-container)' : 'var(--color-surface-container-high)',
              color: selectedTier === 'custom' ? 'var(--color-on-secondary)' : 'var(--color-on-surface-variant)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--text-label-md)'
            }}
          >
            <span>Custom Amount</span>
            {selectedTier === 'custom' && <MaterialIcon icon="edit" className="text-[14px]" />}
          </button>
        </div>
      </div>

      {/* Featured Tier Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-[var(--spacing-gutter-desktop)] items-stretch">
        {/* Tier 1: Coffee Supporter ($3) */}
        <div
          className={`group relative cursor-pointer p-[var(--spacing-space-xl)] rounded-lg transition-all duration-300 hover:-translate-y-1.5 flex flex-col justify-between shadow-lg ${
            selectedTier === 'coffee' ? 'ring-2 ring-[var(--color-primary-container)]' : ''
          }`}
          style={{ backgroundColor: 'var(--color-surface-container-low)' }}
          onClick={() => onSelectTier('coffee', 3)}
        >
          <div className="flex flex-col">
            <div className="flex items-center justify-between mb-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center group-hover:scale-110 transition-transform"
                style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-primary)' }}
              >
                <MaterialIcon icon="coffee" className="text-[26px]" />
              </div>
              <span
                className="px-[var(--spacing-space-sm)] py-[var(--spacing-space-xxs)] rounded-full uppercase"
                style={{
                  backgroundColor: 'var(--color-surface-container-high)',
                  color: 'var(--color-on-surface-variant)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-caption-code)'
                }}
              >
                Micro-Sponsor
              </span>
            </div>

            <h3 className="mb-[var(--spacing-space-xxs)] font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
              Coffee Supporter
            </h3>
            <div className="flex items-baseline gap-[var(--spacing-space-xxs)] mb-[var(--spacing-space-md)]">
              <span className="font-bold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-display-lg)', color: 'var(--color-on-surface)' }}>
                $3
              </span>
              <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                one-time
              </span>
            </div>

            <p className="leading-relaxed mb-[var(--spacing-space-lg)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
              Funds <strong style={{ color: 'var(--color-on-surface)' }}>500 hours</strong> of Cloudflare R2 regional model chunk downloads for mobile clients in low-bandwidth areas.
            </p>
          </div>

          <button
            type="button"
            className="w-full py-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] rounded-full transition-colors flex items-center justify-center gap-[var(--spacing-space-xs)]"
            style={{
              backgroundColor: selectedTier === 'coffee' ? 'var(--color-primary-container)' : 'var(--color-surface-container-high)',
              color: selectedTier === 'coffee' ? 'var(--color-on-primary)' : 'var(--color-on-surface)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--text-label-lg)'
            }}
          >
            <span>{selectedTier === 'coffee' ? 'Selected • $3' : 'Select $3'}</span>
            <MaterialIcon icon={selectedTier === 'coffee' ? 'check_circle' : 'arrow_forward'} className="text-[18px]" />
          </button>
        </div>

        {/* Tier 2: Language Champion ($10 - Popular) */}
        <div
          className={`group relative cursor-pointer p-[var(--spacing-space-xl)] rounded-lg transition-all duration-300 hover:-translate-y-1.5 flex flex-col justify-between shadow-2xl overflow-hidden ${
            selectedTier === 'language' ? 'ring-2 ring-[var(--color-primary-container)]' : ''
          }`}
          style={{
            backgroundImage: 'linear-gradient(to bottom, var(--color-surface-container-low), var(--color-surface-container-low), rgba(134, 3, 156, 0.2))'
          }}
          onClick={() => onSelectTier('language', 10)}
        >
          <div className="absolute inset-x-0 top-0 h-1.5" style={{ backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary), var(--color-primary-container))' }}></div>
          <div className="absolute -top-12 -right-12 w-32 h-32 rounded-full blur-2xl pointer-events-none" style={{ backgroundColor: 'rgba(249, 171, 255, 0.15)' }}></div>

          <div className="flex flex-col">
            <div className="flex items-center justify-between mb-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center shadow-[0_4px_16px_rgba(33,150,243,0.4)] group-hover:scale-110 transition-transform"
                style={{ backgroundImage: 'linear-gradient(to top right, var(--color-primary-container), var(--color-secondary))', color: 'var(--color-on-primary)' }}
              >
                <MaterialIcon icon="translate" className="text-[26px]" />
              </div>
              <span
                className="px-[var(--spacing-space-sm)] py-[var(--spacing-space-xxs)] rounded-full font-bold uppercase tracking-wider shadow-sm"
                style={{
                  backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary))',
                  color: 'var(--color-on-primary)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-caption-code)'
                }}
              >
                ★ Popular
              </span>
            </div>

            <h3 className="mb-[var(--spacing-space-xxs)] flex items-center gap-[var(--spacing-space-xs)] font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
              Language Champion
            </h3>
            <div className="flex items-baseline gap-[var(--spacing-space-xxs)] mb-[var(--spacing-space-md)]">
              <span className="font-bold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-display-lg)', color: 'var(--color-primary)' }}>
                $10
              </span>
              <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                one-time
              </span>
            </div>

            <p className="leading-relaxed mb-[var(--spacing-space-lg)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
              Sponsors targeted GPU compute for fine-tuning regional African dialect weights (<strong style={{ color: 'var(--color-on-surface)' }}>Shona, isiZulu, Sepedi</strong>) on HuggingFace Whisper.
            </p>
          </div>

          <button
            type="button"
            className="w-full py-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] rounded-full shadow-[0_4px_20px_rgba(33,150,243,0.35)] transition-opacity flex items-center justify-center gap-[var(--spacing-space-xs)] hover:opacity-95"
            style={{
              backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary))',
              color: 'var(--color-on-primary)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--text-label-lg)'
            }}
          >
            <span>{selectedTier === 'language' ? 'Selected • $10' : 'Select $10'}</span>
            <MaterialIcon icon={selectedTier === 'language' ? 'check_circle' : 'arrow_forward'} className="text-[18px]" />
          </button>
        </div>

        {/* Tier 3: Custom Fuel / Any Scale */}
        <div
          className={`group relative p-[var(--spacing-space-xl)] rounded-lg transition-all duration-300 hover:-translate-y-1.5 flex flex-col justify-between shadow-lg ${
            selectedTier === 'custom' || (selectedAmount !== 3 && selectedAmount !== 10) ? 'ring-2 ring-[var(--color-primary-container)]' : ''
          }`}
          style={{ backgroundColor: 'var(--color-surface-container-low)' }}
          onClick={(e) => {
            if ((e.target as HTMLElement).tagName !== 'INPUT' && (e.target as HTMLElement).tagName !== 'TEXTAREA') {
              onSelectTier('custom', customAmount);
            }
          }}
        >
          <div className="flex flex-col">
            <div className="flex items-center justify-between mb-[var(--spacing-space-md)]">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center group-hover:scale-110 transition-transform"
                style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-secondary)' }}
              >
                <MaterialIcon icon="bolt" className="text-[26px]" />
              </div>
              <span
                className="px-[var(--spacing-space-sm)] py-[var(--spacing-space-xxs)] rounded-full uppercase"
                style={{
                  backgroundColor: 'var(--color-surface-container-high)',
                  color: 'var(--color-on-surface-variant)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-caption-code)'
                }}
              >
                Any Scale
              </span>
            </div>

            <h3 className="mb-[var(--spacing-space-xxs)] font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
              Custom Fuel
            </h3>

            <div className="relative flex items-center mb-[var(--spacing-space-md)]">
              <span className="absolute left-[var(--spacing-space-md)] font-bold" style={{ color: 'var(--color-primary)', fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-md)' }}>
                $
              </span>
              <input
                className="w-full pl-[var(--spacing-space-xl)] pr-[var(--spacing-space-md)] py-[var(--spacing-space-xs)] rounded-full font-bold transition-all focus:outline-none focus:ring-1"
                style={{
                  backgroundColor: 'var(--color-surface-container-high)',
                  color: 'var(--color-on-surface)',
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--text-headline-md)',
                  borderColor: 'var(--color-primary-container)'
                }}
                id="custom-amount-input"
                min="1"
                step="1"
                type="number"
                value={customAmount || ''}
                onChange={(e) => {
                  const val = Number(e.target.value) || 0;
                  onCustomAmountChange(val);
                  onSelectTier('custom', val);
                }}
                onClick={() => onSelectTier('custom', customAmount)}
              />
              <span className="absolute right-[var(--spacing-space-md)] uppercase" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                USD
              </span>
            </div>

            <div className="flex flex-col gap-[var(--spacing-space-xxs)] mb-[var(--spacing-space-md)]">
              <label className="uppercase" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }} htmlFor="gift-message">
                Dialect shout-out or gift note
              </label>
              <textarea
                className="w-full p-[var(--spacing-space-sm)] rounded transition-all resize-none focus:outline-none focus:ring-1 placeholder:text-[var(--color-outline)]"
                style={{
                  backgroundColor: 'var(--color-surface-container-high)',
                  color: 'var(--color-on-surface)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-body-sm)'
                }}
                id="gift-message"
                placeholder="e.g., Makorokoto! Keep ChiShona transcription open & blazing fast."
                rows={2}
                value={giftMessage}
                onChange={(e) => onGiftMessageChange(e.target.value)}
                onClick={() => onSelectTier('custom', customAmount)}
              ></textarea>
            </div>
          </div>

          <button
            type="button"
            className="w-full py-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] rounded-full transition-colors flex items-center justify-center gap-[var(--spacing-space-xs)] hover:bg-[var(--color-surface-bright)]"
            style={{
              backgroundColor: selectedTier === 'custom' ? 'var(--color-primary-container)' : 'var(--color-surface-container-high)',
              color: selectedTier === 'custom' ? 'var(--color-on-primary)' : 'var(--color-on-surface)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--text-label-lg)'
            }}
            id="select-custom-btn"
            onClick={() => onSelectTier('custom', customAmount)}
          >
            <span>{selectedTier === 'custom' ? `Selected • $${customAmount} USD` : `Commit $${customAmount} USD`}</span>
            <MaterialIcon icon="volunteer_activism" className="text-[18px]" />
          </button>
        </div>
      </div>
    </div>
  );
};
