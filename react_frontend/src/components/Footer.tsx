import React from 'react';
import { NavLink } from 'react-router-dom';

export const Footer: React.FC = () => {
  return (
    <footer
      className="w-full border-t"
      style={{
        backgroundColor: 'var(--color-surface-container-lowest)',
        borderColor: 'rgba(64, 71, 82, 0.3)',
        padding: 'var(--spacing-space-2xl) 0',
      }}
    >
      <div
        className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between"
        style={{
          paddingLeft: 'var(--spacing-margin-mobile)',
          paddingRight: 'var(--spacing-margin-mobile)',
          gap: 'var(--spacing-space-lg)',
        }}
      >
        <div className="flex flex-col text-center md:text-left" style={{ gap: 'var(--spacing-space-xxs)' }}>
          <div className="flex items-center justify-center md:justify-start" style={{ gap: 'var(--spacing-space-xs)' }}>
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-lg)', fontWeight: 500, color: 'var(--color-on-surface)' }}>
              Captionary
            </span>
            <span style={{ color: 'var(--color-outline-variant)' }}>•</span>
            <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
              AGPL-3.0 License
            </span>
          </div>
          <p style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-body-sm)', color: 'var(--color-on-surface-variant)' }}>
            Privacy-first AI speech infrastructure for creators worldwide.
          </p>
        </div>

        <div
          className="flex items-center rounded-full border"
          style={{
            gap: 'var(--spacing-space-xs)',
            padding: 'var(--spacing-space-xs) var(--spacing-space-md)',
            backgroundColor: 'var(--color-surface-container-low)',
            borderColor: 'rgba(64, 71, 82, 0.3)',
          }}
        >
          <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-caption-code)', color: 'var(--color-on-surface-variant)' }}>
            Offline-first Android app · Captionary Website
          </span>
        </div>

        <div className="flex items-center" style={{ gap: 'var(--spacing-space-md)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-md)' }}>
          <NavLink to="/download" className="transition-colors" style={{ color: 'var(--color-on-surface-variant)' }}>Download APK</NavLink>
          <NavLink to="/" className="transition-colors" style={{ color: 'var(--color-on-surface-variant)' }}>Donate</NavLink>
          <NavLink to="/about" className="transition-colors" style={{ color: 'var(--color-on-surface-variant)' }}>About</NavLink>
        </div>
      </div>
    </footer>
  );
};
