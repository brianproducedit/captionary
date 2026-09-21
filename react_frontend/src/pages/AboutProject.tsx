import React from 'react';
import { MaterialIcon } from '../components/MaterialIcon';
import captionaryLogo from '../assets/images/captionary_logo.png';

export const AboutProject: React.FC = () => {
  return (
    <div className="max-w-7xl mx-auto pb-[var(--spacing-space-xl)]" style={{ paddingLeft: 'var(--spacing-margin-mobile)', paddingRight: 'var(--spacing-margin-mobile)' }}>
      <div className="flex flex-col w-full">
        {/* Top Ambient Glow Aura */}
        <div className="relative w-full overflow-hidden">
          <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[720px] h-[360px] blur-[130px] pointer-events-none rounded-full"
            style={{ backgroundImage: 'linear-gradient(to right, rgba(33, 150, 243, 0.2), rgba(134, 3, 156, 0.25), rgba(158, 202, 255, 0.1))' }}>
          </div>

          {/* Hero Section */}
          <section className="relative pt-8 pb-[var(--spacing-space-3xl)] flex flex-col items-center text-center max-w-5xl mx-auto px-[var(--spacing-margin-mobile)]">
            <div className="inline-flex items-center gap-[var(--spacing-space-xs)] px-[var(--spacing-space-md)] py-[var(--spacing-space-xxs)] rounded-full mb-[var(--spacing-space-lg)] shadow-[0_0_20px_rgba(33,150,243,0.2)]"
              style={{ backgroundColor: 'var(--color-surface-container-high)' }}>
              <span className="w-2 h-2 rounded-full animate-ping" style={{ backgroundColor: 'var(--color-tertiary)' }}></span>
              <span className="font-semibold uppercase tracking-widest"
                style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-tertiary)' }}>
                Open-Source & Independent
              </span>
            </div>

            <div className="relative mb-[var(--spacing-space-lg)] group">
              <div className="absolute -inset-1.5 rounded-full blur-md opacity-70 group-hover:opacity-100 transition duration-500"
                style={{ backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary-container))' }}>
              </div>
              <div className="relative p-[var(--spacing-space-xs)] rounded-full flex items-center justify-center"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
                <img alt="Captionary Logo" className="w-24 h-24 md:w-28 md:h-28 rounded-full object-cover" src={captionaryLogo} />
              </div>
            </div>

            <h1 className="tracking-tight font-bold max-w-4xl mx-auto leading-tight text-2xl sm:text-4xl md:text-5xl"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--color-on-surface)' }}>
              Empowering Creators with{' '}
              <span className="bg-clip-text text-transparent"
                style={{ backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-primary), var(--color-secondary))' }}>
                Private, Fast Captions
              </span>
            </h1>

            <p className="mt-[var(--spacing-space-md)] max-w-3xl text-sm sm:text-base md:text-lg leading-relaxed"
              style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface-variant)' }}>
              Captionary is a free, fast, and secure tool for creators. We believe your content is yours, which is why your audio stays on your device and never goes to the cloud.
            </p>

            {/* Quick Highlights Grid */}
            <div className="mt-[var(--spacing-space-2xl)] grid grid-cols-2 sm:grid-cols-4 gap-2.5 sm:gap-4 w-full max-w-4xl">
              <div className="p-3 sm:p-4 rounded-xl flex flex-col items-center justify-center text-center"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
                <span className="font-bold text-xl sm:text-2xl" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-primary)' }}>100%</span>
                <span className="uppercase tracking-wider mt-[var(--spacing-space-xxs)] text-[10px] sm:text-[11px]" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface-variant)' }}>Free to Use</span>
              </div>
              <div className="p-3 sm:p-4 rounded-xl flex flex-col items-center justify-center text-center"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
                <span className="font-bold text-xl sm:text-2xl" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-tertiary)' }}>Private</span>
                <span className="uppercase tracking-wider mt-[var(--spacing-space-xxs)] text-[10px] sm:text-[11px]" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface-variant)' }}>On-Device Only</span>
              </div>
              <div className="p-3 sm:p-4 rounded-xl flex flex-col items-center justify-center text-center"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
                <span className="font-bold text-xl sm:text-2xl" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-secondary)' }}>Fast</span>
                <span className="uppercase tracking-wider mt-[var(--spacing-space-xxs)] text-[10px] sm:text-[11px]" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface-variant)' }}>Instant Results</span>
              </div>
              <div className="p-3 sm:p-4 rounded-xl flex flex-col items-center justify-center text-center"
                style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
                <span className="font-bold text-xl sm:text-2xl" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface)' }}>AGPL-3.0</span>
                <span className="uppercase tracking-wider mt-[var(--spacing-space-xxs)] text-[10px] sm:text-[11px]" style={{ fontFamily: 'var(--font-body)', color: 'var(--color-on-surface-variant)' }}>Open Source</span>
              </div>
            </div>
          </section>
        </div>

        {/* Visual Accent Divider Wave */}
        <div className="w-full max-w-6xl mx-auto px-[var(--spacing-margin-mobile)] flex items-center justify-center gap-[var(--spacing-space-xs)] py-[var(--spacing-space-sm)] opacity-40">
          <span className="h-0.5 w-12 rounded-full" style={{ backgroundColor: 'var(--color-primary-container)' }}></span>
          <span className="h-1 w-2 rounded-full" style={{ backgroundColor: 'var(--color-secondary)' }}></span>
          <span className="h-0.5 w-32 rounded-full" style={{ backgroundImage: 'linear-gradient(to right, var(--color-secondary-container), transparent)' }}></span>
        </div>

        {/* Core Pillars Section */}
        <section className="py-[var(--spacing-space-2xl)] max-w-7xl mx-auto w-full px-[var(--spacing-margin-mobile)]">
          <div className="flex flex-col md:flex-row items-start md:items-end justify-between mb-[var(--spacing-space-xl)] gap-[var(--spacing-space-sm)]">
            <div>
              <span className="uppercase tracking-widest font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-primary)' }}>Core Philosophy</span>
              <h2 className="font-bold mt-[var(--spacing-space-xxs)]" style={{ fontFamily: 'var(--font-display)', fontSize: 'var(--text-headline-xl)', color: 'var(--color-on-surface)' }}>Built for Creators</h2>
            </div>
            <p className="max-w-md" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
              Designed from the ground up to give creators the tools they need without the subscription fees or privacy compromises.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
            {/* Pillar 1 */}
            <div className="group p-5 sm:p-8 rounded-2xl relative overflow-hidden transition-all duration-300 flex flex-col justify-between hover:shadow-[0_8px_30px_rgba(33,150,243,0.15)]"
              style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
              <div className="absolute top-0 right-0 w-32 h-32 rounded-bl-full pointer-events-none transition duration-500 group-hover:scale-110"
                style={{ backgroundColor: 'rgba(33, 150, 243, 0.1)' }}></div>
              <div>
                <div className="w-12 h-12 rounded-full flex items-center justify-center mb-[var(--spacing-space-lg)] shadow-inner"
                  style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-primary)' }}>
                  <MaterialIcon icon="lock" className="text-2xl" />
                </div>
                <span className="uppercase tracking-wider font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-primary)' }}>Privacy First</span>
                <h3 className="font-semibold mt-[var(--spacing-space-xs)] mb-[var(--spacing-space-sm)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>Local Processing</h3>
                <p className="leading-relaxed" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
                  Your audio stays on your device. We don't upload your content to our servers, ensuring complete privacy and security for your unreleased videos.
                </p>
              </div>
            </div>

            {/* Pillar 2 */}
            <div className="group p-5 sm:p-8 rounded-2xl relative overflow-hidden transition-all duration-300 flex flex-col justify-between hover:shadow-[0_8px_30px_rgba(120,220,119,0.15)]"
              style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
              <div className="absolute top-0 right-0 w-32 h-32 rounded-bl-full pointer-events-none transition duration-500 group-hover:scale-110"
                style={{ backgroundColor: 'rgba(120, 220, 119, 0.1)' }}></div>
              <div>
                <div className="w-12 h-12 rounded-full flex items-center justify-center mb-[var(--spacing-space-lg)] shadow-inner"
                  style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-tertiary)' }}>
                  <MaterialIcon icon="speed" className="text-2xl" />
                </div>
                <span className="uppercase tracking-wider font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-tertiary)' }}>Performance</span>
                <h3 className="font-semibold mt-[var(--spacing-space-xs)] mb-[var(--spacing-space-sm)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>Lightning Fast</h3>
                <p className="leading-relaxed" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
                  By processing locally, we eliminate the need to upload large video files over slow connections. Get your captions instantly, wherever you are.
                </p>
              </div>
            </div>

            {/* Pillar 3 */}
            <div className="group p-5 sm:p-8 rounded-2xl relative overflow-hidden transition-all duration-300 flex flex-col justify-between hover:shadow-[0_8px_30px_rgba(249,171,255,0.15)]"
              style={{ backgroundColor: 'var(--color-surface-container-low)' }}>
              <div className="absolute top-0 right-0 w-32 h-32 rounded-bl-full pointer-events-none transition duration-500 group-hover:scale-110"
                style={{ backgroundColor: 'rgba(249, 171, 255, 0.1)' }}></div>
              <div>
                <div className="w-12 h-12 rounded-full flex items-center justify-center mb-[var(--spacing-space-lg)] shadow-inner"
                  style={{ backgroundColor: 'var(--color-surface-container-high)', color: 'var(--color-secondary)' }}>
                  <MaterialIcon icon="code_blocks" className="text-2xl" />
                </div>
                <span className="uppercase tracking-wider font-semibold" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-secondary)' }}>Open Source - Beta</span>
                <h3 className="font-semibold mt-[var(--spacing-space-xs)] mb-[var(--spacing-space-sm)]" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-headline-sm)', color: 'var(--color-on-surface)' }}>Beta Program is Free</h3>
                <p className="leading-relaxed" style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-md)', color: 'var(--color-on-surface-variant)' }}>
                  {/* Captionary is open source under the AGPL-3.0 license. This means it will always remain free, with no hidden subscriptions or paywalls. */}
                  Captionary is still in beta so it will remain free until its performance is efficient.
                </p>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};
