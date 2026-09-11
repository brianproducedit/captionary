import React from 'react';

interface GradientPillButtonProps {
  label: string;
  icon?: string;
  onClick?: () => void;
  href?: string;
  className?: string;
}

export const GradientPillButton: React.FC<GradientPillButtonProps> = ({ label, icon, onClick, href, className = '' }) => {
  const classes = `px-[var(--spacing-space-lg)] py-[var(--spacing-space-xs)] rounded-full bg-gradient-to-r from-[var(--color-primary-container)] to-[var(--color-secondary-container)] text-[var(--color-on-primary)] font-[var(--text-label-lg--font-weight)] text-[length:var(--text-label-lg)] leading-[var(--text-label-lg--line-height)] shadow-[0px_4px_20px_rgba(33,150,243,0.35)] hover:shadow-[0px_6px_24px_rgba(156,39,176,0.45)] transition-all flex items-center gap-[var(--spacing-space-xs)] cursor-pointer ${className}`;

  if (href) {
    return (
      <a className={classes} href={href}>
        {icon && <span className="material-symbols-outlined text-lg">{icon}</span>}
        <span>{label}</span>
      </a>
    );
  }

  return (
    <button className={classes} onClick={onClick}>
      {icon && <span className="material-symbols-outlined text-lg">{icon}</span>}
      <span>{label}</span>
    </button>
  );
};
