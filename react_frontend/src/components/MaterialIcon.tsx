import React from 'react';

interface MaterialIconProps {
  icon: string;
  className?: string;
  filled?: boolean;
  style?: React.CSSProperties;
}

export const MaterialIcon: React.FC<MaterialIconProps> = ({ icon, className = '', filled = false, style = {} }) => {
  return (
    <span
      className={`material-symbols-outlined ${className}`}
      style={{
        fontVariationSettings: filled ? "'FILL' 1" : "'FILL' 0",
        ...style
      }}
    >
      {icon}
    </span>
  );
};
