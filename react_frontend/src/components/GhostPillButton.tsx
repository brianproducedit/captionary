import React from 'react';

interface GhostPillButtonProps {
  label: string;
  icon?: string;
  onClick?: () => void;
  href?: string;
  className?: string;
  textColor?: string;
}

export const GhostPillButton: React.FC<GhostPillButtonProps> = ({ label, icon, onClick, href, className = '', textColor }) => {
  const colorStyle = textColor ? { color: textColor } : {};
  const classes = `px-[var(--spacing-space-lg)] py-[var(--spacing-space-xs)] rounded-full bg-[var(--color-surface-container-high)] hover:bg-[var(--color-surface-bright)] text-[var(--color-on-surface)] font-[var(--text-label-lg--font-weight)] text-[length:var(--text-label-lg)] leading-[var(--text-label-lg--line-height)] transition-colors flex items-center gap-[var(--spacing-space-xs)] shadow-sm cursor-pointer ${className}`;

  if (href) {
    return (
      <a className={classes} href={href} style={colorStyle}>
        {icon && <span className="material-symbols-outlined text-lg">{icon}</span>}
        <span>{label}</span>
      </a>
    );
  }

  return (
    <button className={classes} onClick={onClick} style={colorStyle}>
      {icon && <span className="material-symbols-outlined text-lg">{icon}</span>}
      <span>{label}</span>
    </button>
  );
};
