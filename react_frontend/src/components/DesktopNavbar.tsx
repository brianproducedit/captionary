import React, { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import captionaryLogo from '../assets/images/captionary_logo.png';
import { MaterialIcon } from './MaterialIcon';
import { publicConfig } from '../config/public';

interface NavItem {
  label: string;
  path: string;
  icon: string;
  subtitle: string;
  badge?: string;
  accentColor: string;
}

const navItems: NavItem[] = [
  {
    label: 'Download',
    path: '/download',
    icon: 'download',
    subtitle: 'Offline v1.0.1 APKs for Android',
    badge: 'v1.0.1',
    accentColor: '#2196f3',
  },
  {
    label: 'Donate',
    path: '/',
    icon: 'coffee',
    subtitle: 'Support independent speech models',
    badge: 'Support ☕',
    accentColor: '#86039c',
  },
  {
    label: 'About',
    path: '/about',
    icon: 'auto_awesome',
    subtitle: '100% offline, AGPL-3.0 open source',
    badge: 'AGPL-3.0',
    accentColor: '#42a547',
  },
];

export const DesktopNavbar: React.FC = () => {
  const location = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [location.pathname]);

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMobileMenuOpen]);

  // Close mobile menu on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isMobileMenuOpen) {
        setIsMobileMenuOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isMobileMenuOpen]);

  const isNavActive = (path: string) => {
    if (path === '/') {
      return (
        location.pathname === '/' ||
        location.pathname === '/donate' ||
        location.pathname === '/support'
      );
    }
    return location.pathname === path;
  };

  return (
    <>
      <header
        className="fixed top-0 left-0 right-0 z-50 border-b"
        style={{
          backgroundColor: 'rgba(19, 19, 19, 0.92)',
          backdropFilter: 'blur(24px)',
          WebkitBackdropFilter: 'blur(24px)',
          borderColor: 'rgba(64, 71, 82, 0.35)',
          boxShadow: '0 2px 20px rgba(0, 0, 0, 0.65)',
        }}
      >
        <div className="h-16 sm:h-20 max-w-7xl mx-auto flex items-center justify-between px-4 sm:px-6 md:px-8 gap-3">
          {/* Logo & Brand Title */}
          <NavLink
            to="/"
            className="flex items-center gap-2.5 sm:gap-3 shrink-0 group focus:outline-none"
            aria-label="Captionary Home"
          >
            <div
              className="rounded-full p-1 transition-transform group-hover:scale-105"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                border: '1px solid rgba(255, 255, 255, 0.12)',
              }}
            >
              <img
                alt="Captionary logo"
                className="w-8 h-8 sm:w-9 sm:h-9 rounded-full object-cover"
                src={captionaryLogo}
              />
            </div>
            <div className="flex flex-col min-w-0">
              <span
                className="tracking-tight font-bold text-lg sm:text-xl text-white group-hover:text-blue-300 transition-colors"
                style={{ fontFamily: 'var(--font-display)' }}
              >
                Captionary
              </span>
              <span
                className="hidden lg:inline-block text-[11px] text-gray-400"
                style={{ fontFamily: 'var(--font-body)' }}
              >
                AI Speech Studio for African Creators
              </span>
            </div>
          </NavLink>

          {/* Desktop Nav Pills (Hidden on Mobile) */}
          <nav
            className="hidden md:flex items-center rounded-full border p-1 shrink-0"
            style={{
              gap: 'var(--spacing-space-xs)',
              backgroundColor: 'var(--color-surface-container-low)',
              borderColor: 'rgba(64, 71, 82, 0.4)',
            }}
          >
            {navItems.map((item) => {
              const active = isNavActive(item.path);
              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className="rounded-full px-4 py-1.5 transition-all text-sm font-medium"
                  style={{
                    fontFamily: 'var(--font-body)',
                    color: active ? 'var(--color-on-surface)' : 'var(--color-on-surface-variant)',
                    backgroundColor: active ? 'var(--color-surface-container-highest)' : 'transparent',
                    boxShadow: active ? 'inset 0 1px 2px rgba(0,0,0,0.3)' : 'none',
                    border: active ? '1px solid rgba(158, 202, 255, 0.25)' : '1px solid transparent',
                  }}
                >
                  {item.label}
                </NavLink>
              );
            })}
          </nav>

          {/* Right Actions Area */}
          <div className="flex items-center gap-2 sm:gap-3 shrink-0">
            {/* Desktop "Get App" pill button */}
            <NavLink
              to="/download"
              className="hidden lg:inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 transition-all hover:bg-gray-800 text-xs font-semibold"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                borderColor: 'rgba(33, 150, 243, 0.4)',
                color: 'var(--color-primary)',
              }}
            >
              <span>Get App</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            </NavLink>

            {/* Quick Action "Donate ☕" Button */}
            <NavLink
              to="/donate"
              className="inline-flex items-center justify-center rounded-full px-3.5 py-1.5 sm:px-5 sm:py-2 text-xs sm:text-sm font-semibold transition-all transform hover:scale-105 active:scale-95 shadow-md"
              style={{
                backgroundImage:
                  'linear-gradient(to right, var(--color-primary-container), var(--color-secondary-container))',
                color: 'var(--color-on-primary)',
                fontFamily: 'var(--font-body)',
                boxShadow: '0 4px 16px rgba(33, 150, 243, 0.35)',
              }}
            >
              Donate ☕
            </NavLink>

            {/* Mobile Hamburger Toggle Button */}
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              aria-label={isMobileMenuOpen ? 'Close navigation menu' : 'Open navigation menu'}
              aria-expanded={isMobileMenuOpen}
              className="md:hidden flex items-center justify-center w-10 h-10 rounded-full border transition-all cursor-pointer"
              style={{
                backgroundColor: isMobileMenuOpen
                  ? 'var(--color-surface-container-highest)'
                  : 'var(--color-surface-container-high)',
                borderColor: isMobileMenuOpen
                  ? 'rgba(158, 202, 255, 0.5)'
                  : 'rgba(64, 71, 82, 0.4)',
                color: 'var(--color-on-surface)',
              }}
            >
              <MaterialIcon
                icon={isMobileMenuOpen ? 'close' : 'menu'}
                className="text-2xl transition-transform duration-200"
              />
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Drawer Backdrop */}
      {isMobileMenuOpen && (
        <div
          role="presentation"
          onClick={() => setIsMobileMenuOpen(false)}
          className="fixed inset-0 top-16 sm:top-20 z-40 bg-black/80 backdrop-blur-md md:hidden transition-opacity duration-300"
        />
      )}

      {/* Mobile Navigation Drawer Panel */}
      {isMobileMenuOpen && (
        <nav
          aria-label="Mobile Navigation"
          className="fixed top-16 sm:top-20 left-0 right-0 z-50 max-h-[calc(100vh-4rem)] sm:max-h-[calc(100vh-5rem)] overflow-y-auto border-b md:hidden shadow-2xl p-4 sm:p-6 flex flex-col gap-4 transition-all duration-300"
          style={{
            backgroundColor: 'rgba(19, 19, 19, 0.98)',
            borderColor: 'rgba(64, 71, 82, 0.4)',
            backdropFilter: 'blur(28px)',
            WebkitBackdropFilter: 'blur(28px)',
          }}
        >
          {/* Navigation Links List */}
          <div className="flex flex-col gap-2">
            {navItems.map((item) => {
              const active = isNavActive(item.path);
              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  onClick={() => setIsMobileMenuOpen(false)}
                  className="flex items-center justify-between p-3 rounded-2xl transition-all"
                  style={{
                    backgroundColor: active
                      ? 'var(--color-surface-container-high)'
                      : 'var(--color-surface-container-lowest)',
                    border: '1px solid',
                    borderColor: active
                      ? 'rgba(158, 202, 255, 0.35)'
                      : 'rgba(64, 71, 82, 0.25)',
                  }}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                      style={{
                        backgroundColor: `${item.accentColor}20`,
                        color: item.accentColor,
                        border: `1px solid ${item.accentColor}40`,
                      }}
                    >
                      <MaterialIcon icon={item.icon} className="text-xl" />
                    </div>
                    <div className="flex flex-col min-w-0">
                      <div className="flex items-center gap-2">
                        <span
                          className="font-bold text-sm"
                          style={{
                            color: active ? 'var(--color-primary)' : 'var(--color-on-surface)',
                            fontFamily: 'var(--font-display)',
                          }}
                        >
                          {item.label}
                        </span>
                        {item.badge && (
                          <span
                            className="px-2 py-0.5 rounded-full text-[10px] font-semibold"
                            style={{
                              backgroundColor: `${item.accentColor}25`,
                              color: item.accentColor,
                              border: `1px solid ${item.accentColor}40`,
                            }}
                          >
                            {item.badge}
                          </span>
                        )}
                      </div>
                      <span
                        className="text-xs truncate"
                        style={{ color: 'var(--color-on-surface-variant)' }}
                      >
                        {item.subtitle}
                      </span>
                    </div>
                  </div>
                  <MaterialIcon
                    icon="chevron_right"
                    className="text-xl shrink-0"
                    style={{ color: 'var(--color-outline)' }}
                  />
                </NavLink>
              );
            })}
          </div>

          {/* Quick Action Button in Drawer */}
          <div className="pt-2 border-t flex flex-col gap-2.5" style={{ borderColor: 'rgba(64, 71, 82, 0.3)' }}>
            <NavLink
              to="/download"
              onClick={() => setIsMobileMenuOpen(false)}
              className="w-full flex items-center justify-center gap-2 px-5 py-3.5 rounded-full font-bold text-sm transition-transform active:scale-95 shadow-lg"
              style={{
                backgroundImage:
                  'linear-gradient(to right, var(--color-primary-container), var(--color-secondary-container))',
                color: 'var(--color-on-primary)',
              }}
            >
              <MaterialIcon icon="download" className="text-xl" />
              <span>Download Universal APK (v1.0.1)</span>
            </NavLink>

            <a
              href={publicConfig.githubUrl}
              target="_blank"
              rel="noreferrer"
              className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-full border text-xs font-semibold transition-colors hover:bg-gray-800"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                borderColor: 'rgba(64, 71, 82, 0.4)',
                color: 'var(--color-on-surface-variant)',
              }}
            >
              <MaterialIcon icon="open_in_new" className="text-sm" />
              <span>View Source Code on GitHub</span>
            </a>
          </div>

          {/* Mobile Menu Footer Info */}
          <div className="text-center pt-1 text-[11px]" style={{ color: 'var(--color-outline)' }}>
            Captionary v1.0.1 · 100% Offline AI Speech Studio · AGPL-3.0
          </div>
        </nav>
      )}
    </>
  );
};
