import React, { useState } from 'react';
import { useLocation, Link } from 'react-router-dom';
import { MaterialIcon } from '../components/MaterialIcon';
import captionaryLogo from '../assets/images/captionary_logo.png';
import type { PaymentLocationState } from '../types/donation';

export const PaymentConfirmation: React.FC = () => {
  const location = useLocation();
  const state = (location.state as PaymentLocationState) || {};

  const amount = state.amount ?? 10;
  const tierName = state.tierName ?? 'Supporter';
  const paymentMethodTitle = state.paymentMethodTitle ?? 'Standard Checkout';
  const referenceId = state.referenceId ?? '#CAP-89241-ZW';
  const message = state.message;

  const [refCopied, setRefCopied] = useState(false);

  const handleCopyRef = () => {
    navigator.clipboard.writeText(referenceId).then(() => {
      setRefCopied(true);
      setTimeout(() => {
        setRefCopied(false);
      }, 2000);
    });
  };

  const handlePrint = () => {
    window.print();
  };

  // Dynamic Impact Metrics
  const creatorsHelped = Math.round(amount * 5).toLocaleString();
  const hoursSaved = (amount * 12.5).toFixed(1);

  return (
    <div className="max-w-7xl mx-auto pb-[var(--spacing-space-xl)] flex flex-col" style={{ paddingLeft: 'var(--spacing-margin-mobile)', paddingRight: 'var(--spacing-margin-mobile)' }}>
      <div className="flex flex-col w-full">
        <div className="relative max-w-4xl mx-auto w-full pt-8 pb-[var(--spacing-space-xl)] lg:px-0" style={{ paddingLeft: 'var(--spacing-margin-mobile)', paddingRight: 'var(--spacing-margin-mobile)' }}>
          
          {/* Ambient Backdrop Gradient Glow */}
          <div className="absolute -top-12 left-1/2 -translate-x-1/2 w-full max-w-2xl h-80 blur-3xl -z-10 pointer-events-none rounded-full"
               style={{ backgroundImage: 'linear-gradient(to top right, rgba(33, 150, 243, 0.2), rgba(134, 3, 156, 0.25), rgba(120, 220, 119, 0.15))' }}></div>
          
          {/* Main Gratitude Canvas */}
          <div className="relative rounded-lg shadow-2xl overflow-hidden p-[var(--spacing-space-md)] md:p-[var(--spacing-space-2xl)]"
               style={{ backgroundColor: '#141414' }}>
            
            {/* Hero Confirmation Section */}
            <div className="flex flex-col items-center text-center space-y-[var(--spacing-space-md)]">
              {/* Glowing Checkmark Icon Badge */}
              <div className="relative group">
                <div className="absolute -inset-1.5 rounded-full blur-md animate-pulse" style={{ backgroundColor: 'rgba(76, 175, 80, 0.3)' }}></div>
                <div className="relative w-20 h-20 rounded-full flex items-center justify-center shadow-[0_0_30px_rgba(76,175,80,0.35)]"
                     style={{ backgroundColor: '#141414', color: '#4CAF50' }}>
                  <MaterialIcon icon="check_circle" className="text-[44px]" style={{ fontVariationSettings: "'FILL' 1, 'wght' 600" }} />
                </div>
              </div>
              
              {/* Pill Status Badge */}
              <div className="inline-flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full tracking-wide uppercase"
                   style={{ backgroundColor: 'rgba(76, 175, 80, 0.15)', color: '#4CAF50', fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)' }}>
                <span className="w-2 h-2 rounded-full animate-ping" style={{ backgroundColor: '#4CAF50' }}></span>
                <span>Payment Confirmed & Verified</span>
              </div>
              
              {/* Lexend Typography Heading & Subtitle */}
              <div className="max-w-2xl space-y-[var(--spacing-space-xs)]">
                <h1 className="tracking-tight" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-xl)', color: 'var(--color-on-surface)' }}>
                  Thank You for Supporting Captionary!
                </h1>
                <p className="leading-relaxed" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-lg)', color: 'var(--color-on-surface-variant)' }}>
                  Your contribution keeps fast, private speech-to-text tools accessible for creators everywhere.
                </p>
              </div>
            </div>

            {/* Two-Column Details Grid */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-[var(--spacing-space-lg)] mt-[var(--spacing-space-2xl)]">
              {/* Left Column: Transaction Receipt Card (7 cols) */}
              <div className="md:col-span-7 rounded-DEFAULT p-[var(--spacing-space-lg)] flex flex-col justify-between"
                   style={{ backgroundColor: '#1c1b1b' }}>
                <div>
                  <div className="flex items-center justify-between pb-[var(--spacing-space-sm)] mb-[var(--spacing-space-md)] -mx-[var(--spacing-space-lg)] -mt-[var(--spacing-space-lg)] px-[var(--spacing-space-lg)] pt-[var(--spacing-space-md)] rounded-t-DEFAULT"
                       style={{ backgroundColor: 'rgba(42, 42, 42, 0.3)' }}>
                    <div className="flex items-center gap-[var(--spacing-space-xs)]">
                      <MaterialIcon icon="receipt_long" style={{ color: 'var(--color-primary)', fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)' }} />
                      <span style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>Transaction Receipt</span>
                    </div>
                    <span className="px-[var(--spacing-space-xs)] py-[var(--spacing-space-xxs)] rounded-full flex items-center gap-1"
                          style={{ backgroundColor: 'var(--color-surface-container-highest)', color: 'var(--color-tertiary)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)' }}>
                      <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: 'var(--color-tertiary)' }}></span> Settled
                    </span>
                  </div>
                  
                  <div className="space-y-[var(--spacing-space-md)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)' }}>
                    {/* Tier */}
                    <div className="flex items-center justify-between">
                      <span style={{ color: 'var(--color-on-surface-variant)', fontSize: 'var(--text-body-sm)' }}>Contribution Tier</span>
                      <div className="flex items-center gap-[var(--spacing-space-xs)]">
                        <span className="px-[var(--spacing-space-xs)] py-[var(--spacing-space-xxs)] rounded-full flex items-center gap-0.5"
                              style={{ backgroundColor: 'rgba(255, 193, 7, 0.2)', color: '#FFC107', fontSize: 'var(--text-caption-code)' }}>
                          <MaterialIcon icon="star" className="text-[length:var(--text-caption-code)]" filled />
                          {tierName}
                        </span>
                        <span className="font-semibold" style={{ color: 'var(--color-on-surface)', fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)' }}>
                          ${amount.toFixed(2)}
                        </span>
                      </div>
                    </div>
                    
                    {/* Payment Rail */}
                    <div className="flex items-center justify-between">
                      <span style={{ color: 'var(--color-on-surface-variant)', fontSize: 'var(--text-body-sm)' }}>Payment Rail</span>
                      <div className="flex items-center gap-[var(--spacing-space-xs)]">
                        <MaterialIcon icon="payments" className="text-base" style={{ color: 'var(--color-primary)' }} />
                        <span style={{ color: 'var(--color-on-surface)', fontSize: 'var(--text-label-lg)' }}>{paymentMethodTitle}</span>
                      </div>
                    </div>
                    
                    {/* Reference ID with Interactive Copy */}
                    <div className="flex items-center justify-between">
                      <span style={{ color: 'var(--color-on-surface-variant)', fontSize: 'var(--text-body-sm)' }}>Transaction / Ref ID</span>
                      <button className="group flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-xs)] py-[var(--spacing-space-xxs)] rounded-full transition-all hover:text-[var(--color-primary-fixed)] cursor-pointer"
                              style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-primary)', backgroundColor: 'var(--color-surface-container-high)' }}
                              onClick={handleCopyRef}>
                        <span>{referenceId}</span>
                        <MaterialIcon icon="content_copy" className="text-[length:var(--text-caption-code)] group-hover:scale-110 transition-transform" />
                      </button>
                    </div>
                    <div className={`text-right transition-opacity duration-300 -mt-2 ${refCopied ? 'opacity-100' : 'opacity-0'}`}
                         style={{ color: 'var(--color-tertiary)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)' }}>
                      Reference ID copied to clipboard!
                    </div>
                    
                    {/* Timestamp */}
                    <div className="flex items-center justify-between">
                      <span style={{ color: 'var(--color-on-surface-variant)', fontSize: 'var(--text-body-sm)' }}>Timestamp</span>
                      <span style={{ color: 'var(--color-on-surface)', fontSize: 'var(--text-caption-code)' }}>Just now</span>
                    </div>

                    {/* Optional Gift Message / Shout-out */}
                    {message && (
                      <div className="p-3 rounded-lg border border-white/10" style={{ backgroundColor: 'var(--color-surface-container-high)' }}>
                        <div className="text-xs uppercase font-semibold mb-1" style={{ color: 'var(--color-secondary)' }}>
                          Your Note
                        </div>
                        <p className="italic text-xs" style={{ color: 'var(--color-on-surface)' }}>
                          "{message}"
                        </p>
                      </div>
                    )}
                  </div>
                </div>
                
                {/* Bottom Grant Tag */}
                <div className="mt-[var(--spacing-space-lg)] pt-[var(--spacing-space-sm)] p-[var(--spacing-space-sm)] rounded-lg flex items-center gap-[var(--spacing-space-xs)]"
                     style={{ backgroundColor: 'rgba(32, 31, 31, 0.6)' }}>
                  <MaterialIcon icon="verified" className="text-lg" style={{ color: 'var(--color-tertiary)' }} />
                  <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                    Thank you for keeping Captionary open source!
                  </span>
                </div>
              </div>

              {/* Right Column: Direct Real-World Impact Card (5 cols) */}
              <div className="md:col-span-5 rounded-DEFAULT p-[var(--spacing-space-lg)] flex flex-col justify-between relative overflow-hidden"
                   style={{ backgroundImage: 'linear-gradient(to bottom, rgba(42, 42, 42, 0.8), #1c1b1b)' }}>
                <div className="space-y-[var(--spacing-space-md)]">
                  <div className="flex items-center gap-[var(--spacing-space-xs)]">
                    <div className="w-8 h-8 rounded-full flex items-center justify-center"
                         style={{ backgroundImage: 'linear-gradient(to top right, var(--color-primary-container), var(--color-secondary))', color: 'var(--color-on-primary)' }}>
                      <MaterialIcon icon="bolt" className="text-lg" />
                    </div>
                    <span className="font-semibold tracking-wide uppercase" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-lg)', color: 'var(--color-on-surface)' }}>Direct Real-World Impact</span>
                  </div>
                  
                  {/* Primary Highlight Metric */}
                  <div className="space-y-[var(--spacing-space-xxs)] pt-[var(--spacing-space-xs)]">
                    <div className="font-bold bg-clip-text text-transparent"
                         style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-display-lg)', backgroundImage: 'linear-gradient(to right, var(--color-primary-fixed), var(--color-secondary-fixed-dim))' }}>
                      ~{creatorsHelped}
                    </div>
                    <div className="font-medium leading-snug" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>
                      Creators Helped
                    </div>
                    <p className="leading-relaxed pt-[var(--spacing-space-xs)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
                      Your ${amount} contribution helps cover the development and distribution costs for ~{creatorsHelped} creators worldwide who use Captionary.
                    </p>
                  </div>
                  
                  {/* Secondary Metric Block */}
                  <div className="p-[var(--spacing-space-sm)] rounded-DEFAULT flex items-center gap-[var(--spacing-space-sm)]"
                       style={{ backgroundColor: 'rgba(14, 14, 14, 0.8)' }}>
                    <MaterialIcon icon="schedule" className="text-2xl" style={{ color: '#FFC107' }} />
                    <div className="flex flex-col">
                      <span className="font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-md)', color: 'var(--color-on-surface)' }}>Time Saved</span>
                      <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                        Saves creators <strong style={{ color: 'var(--color-tertiary)' }}>~{hoursSaved} hours</strong> of manual subtitling.
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Callouts (Horizontal Desktop Button Group) */}
            <div className="mt-[var(--spacing-space-xl)] pt-[var(--spacing-space-md)] flex flex-col md:flex-row items-center justify-center gap-[var(--spacing-space-md)]">
              {/* Primary Action */}
              <Link to="/"
                    className="w-full md:w-auto px-[var(--spacing-space-xl)] py-[var(--spacing-space-sm)] rounded-full shadow-[0_4px_20px_rgba(33,150,243,0.4)] transition-all flex items-center justify-center gap-[var(--spacing-space-xs)] font-semibold hover:shadow-[0_4px_28px_rgba(156,39,176,0.5)] hover:scale-[1.02] active:scale-[0.98]"
                    style={{ backgroundImage: 'linear-gradient(to right, var(--color-primary-container), #673AB7, #9C27B0)', color: 'var(--color-on-primary)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-lg)' }}>
                <span>Back to Home</span>
                <MaterialIcon icon="arrow_back" className="text-lg" />
              </Link>
              
              {/* Secondary Outline Action */}
              <button className="w-full md:w-auto px-[var(--spacing-space-lg)] py-[var(--spacing-space-sm)] rounded-full transition-colors flex items-center justify-center gap-[var(--spacing-space-xs)] shadow-sm hover:bg-[var(--color-surface-bright)] cursor-pointer"
                      style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-on-surface)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-lg)' }} onClick={handlePrint}>
                <MaterialIcon icon="download" className="text-lg" />
                <span>Download PDF Receipt</span>
              </button>
            </div>

            {/* Footer Brand Sign-off */}
            <div className="mt-[var(--spacing-space-2xl)] pt-[var(--spacing-space-lg)] flex flex-col items-center justify-center gap-[var(--spacing-space-xs)] text-center">
              <div className="flex items-center gap-[var(--spacing-space-xs)]">
                <img alt="Captionary Logo" className="w-7 h-7 rounded-full object-cover shadow-sm" src={captionaryLogo} />
                <span className="tracking-tight font-semibold" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>Captionary</span>
              </div>
              <p className="flex items-center gap-1" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
                Made with <span style={{ color: '#f9abff' }}>❤️</span> for independent creators.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
