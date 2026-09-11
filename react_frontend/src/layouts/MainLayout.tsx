import React from 'react';
import { Outlet } from 'react-router-dom';
import { DesktopNavbar } from '../components/DesktopNavbar';
import { Footer } from '../components/Footer';

export const MainLayout: React.FC = () => {
  return (
    <div
      className="min-h-screen flex flex-col"
      style={{
        backgroundColor: 'var(--color-surface)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--text-body-md)',
        lineHeight: 'var(--text-body-md--line-height)',
        color: 'var(--color-on-surface)',
      }}
    >
      <DesktopNavbar />
      <main className="w-full pt-20 flex-1" style={{ backgroundColor: 'var(--color-surface)' }}>
        <Outlet />
      </main>
      <Footer />
    </div>
  );
};
