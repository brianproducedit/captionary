import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import captionaryLogo from '../assets/images/captionary_logo.png';

const navItems = [
  { label: 'Donate', path: '/' },
  { label: 'About', path: '/about' },
];

export const DesktopNavbar: React.FC = () => {
  const location = useLocation();

  return (
    <header
      className="fixed top-0 left-0 right-0 z-50 border-b"
      style={{
        backgroundColor: 'rgba(19, 19, 19, 0.85)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        borderColor: 'rgba(64, 71, 82, 0.3)',
        boxShadow: '0 1px 16px rgba(0,0,0,0.6)',
      }}
    >
      <div
        className="h-20 max-w-7xl mx-auto flex items-center justify-between"
        style={{
          paddingLeft: 'var(--spacing-margin-mobile)',
          paddingRight: 'var(--spacing-margin-mobile)',
          gap: 'var(--spacing-space-md)',
        }}
      >
        {/* Logo */}
        <div className="flex items-center" style={{ gap: 'var(--spacing-space-sm)' }}>
          <div
            className="rounded-full"
            style={{
              padding: 'var(--spacing-space-xxs)',
              backgroundColor: 'var(--color-surface-container-high)',
            }}
          >
            <img
              alt="Captionary logo"
              className="w-9 h-9 rounded-full object-cover"
              src={captionaryLogo}
            />
          </div>
            <div className="flex flex-col min-w-0">
            <span
                className="tracking-tight font-semibold"
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--text-headline-sm)',
                  lineHeight: 'var(--text-headline-sm--line-height)',
                  color: 'var(--color-on-surface)',
                }}
              >
                Captionary
              </span>
            <span
              className="hidden sm:inline-block"
              style={{
                fontFamily: 'var(--font-body)',
                fontSize: 'var(--text-caption-code)',
                lineHeight: 'var(--text-caption-code--line-height)',
                color: 'var(--color-on-surface-variant)',
              }}
            >
              AI Speech Studio for African Creators
            </span>
          </div>
        </div>

        {/* Nav Pills */}
        <nav
          className="flex items-center rounded-full border overflow-x-auto max-w-[min(100%,16rem)] sm:max-w-none shrink min-w-0"
          style={{
            padding: 'var(--spacing-space-xxs)',
            gap: 'var(--spacing-space-xs)',
            backgroundColor: 'var(--color-surface-container-low)',
            borderColor: 'rgba(64, 71, 82, 0.3)',
          }}
        >
          {navItems.map((item) => {
            const isActive = location.pathname === item.path || 
              (item.path === '/' && (location.pathname === '/donate' || location.pathname === '/support'));
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className="rounded-full transition-colors"
                style={{
                  padding: 'var(--spacing-space-xs) var(--spacing-space-md)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-label-lg)',
                  lineHeight: 'var(--text-label-lg--line-height)',
                  fontWeight: 'var(--text-label-lg--font-weight)' as any,
                  color: isActive ? 'var(--color-on-surface)' : 'var(--color-on-surface-variant)',
                  backgroundColor: isActive ? 'var(--color-surface-container-highest)' : 'transparent',
                  boxShadow: isActive ? 'inset 0 1px 2px rgba(0,0,0,0.3)' : 'none',
                }}
              >
                {item.label}
              </NavLink>
            );
          })}
        </nav>

        {/* Right Actions */}
        <div className="flex items-center" style={{ gap: 'var(--spacing-space-sm)' }}>
          <NavLink
            to="/donate"
            className="rounded-full bg-gradient-to-r transition-all shrink-0 whitespace-nowrap"
            style={{
              padding: 'var(--spacing-space-xs) var(--spacing-space-lg)',
              backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary-container))',
              color: 'var(--color-on-primary)',
              fontFamily: 'var(--font-body)',
              fontSize: 'var(--text-label-lg)',
              lineHeight: 'var(--text-label-lg--line-height)',
              fontWeight: 'var(--text-label-lg--font-weight)' as any,
              boxShadow: '0px 4px 20px rgba(33,150,243,0.35)',
            }}
          >
            Donate ☕
          </NavLink>
        </div>
      </div>
    </header>
  );
};
