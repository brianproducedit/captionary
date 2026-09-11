export interface TierInfo {
  id: string;
  name: string;
  badge: string;
  amount: number;
  icon: string;
  description: string;
  popular?: boolean;
}

export const PRESET_TIERS: TierInfo[] = [
  {
    id: 'coffee',
    name: 'Coffee Supporter',
    badge: 'Micro-Sponsor',
    amount: 3,
    icon: 'coffee',
    description: 'Funds 500 hours of Cloudflare R2 regional model chunk downloads for mobile clients in low-bandwidth areas.'
  },
  {
    id: 'starter',
    name: 'Dialect Starter',
    badge: 'Lexicon Boost',
    amount: 5,
    icon: 'menu_book',
    description: 'Powers phoneme dictionary parsing and vocabulary expansion for under-resourced regional dialects.'
  },
  {
    id: 'language',
    name: 'Language Champion',
    badge: '★ Popular',
    amount: 10,
    icon: 'translate',
    description: 'Sponsors targeted GPU compute for fine-tuning regional African dialect weights (Shona, isiZulu, Sepedi) on Whisper.',
    popular: true
  },
  {
    id: 'architect',
    name: 'Model Architect',
    badge: 'Quantization',
    amount: 25,
    icon: 'memory',
    description: 'Covers edge ONNX/CoreML model quantization runs and automated transcription quality benchmarking.'
  },
  {
    id: 'pillar',
    name: 'Ecosystem Pillar',
    badge: 'Patron',
    amount: 50,
    icon: 'workspace_premium',
    description: 'Directly funds community voice recording stipends and independent dialect preservation grants.'
  }
];

export type PaymentMethodId = 'ecocash' | 'innbucks' | 'card' | 'crypto';

export interface PaymentMethodOption {
  id: PaymentMethodId;
  name: string;
  subtitle: string;
  badge: string;
  badgeBg: string;
  badgeColor: string;
  accentColor: string;
  icon: string;
  description: string;
  features: string[];
}

export const PAYMENT_METHODS: PaymentMethodOption[] = [
  {
    id: 'ecocash',
    name: 'EcoCash USSD Push',
    subtitle: 'Southern Africa • USD & ZiG',
    badge: 'Zero-Fee Local',
    badgeBg: 'rgba(66, 165, 71, 0.2)',
    badgeColor: 'var(--color-tertiary)',
    accentColor: 'var(--color-tertiary)',
    icon: 'contactless',
    description: 'Instant localized mobile money processing. Triggers a direct *151# USSD phone prompt with zero foreign exchange markup.',
    features: ['Direct *151# USSD approval', 'Accepts USD & ZiG wallets', '3-second push delivery']
  },
  {
    id: 'innbucks',
    name: 'InnBucks Voucher & QR',
    subtitle: 'Zimbabwe & Regional • USD',
    badge: 'Instant QR',
    badgeBg: 'rgba(134, 3, 156, 0.25)',
    badgeColor: 'var(--color-secondary)',
    accentColor: 'var(--color-secondary)',
    icon: 'qr_code_scanner',
    description: 'Pay directly via the InnBucks app QR scan or generate a secure 6-digit payment voucher code for in-app redemption.',
    features: ['Instant mobile app QR scan', '6-digit redemption voucher', 'Direct retail cash-in']
  },
  {
    id: 'card',
    name: 'International Card',
    subtitle: 'Worldwide • Stripe, Apple & Google Pay',
    badge: 'Auto-FX Global',
    badgeBg: 'rgba(33, 150, 243, 0.2)',
    badgeColor: 'var(--color-primary)',
    accentColor: 'var(--color-primary)',
    icon: 'credit_card',
    description: 'Direct global card checkout supporting Visa, Mastercard, and American Express with 256-bit SSL encryption.',
    features: ['Visa, Mastercard & Amex', 'Apple Pay & Google Pay ready', '256-bit SSL encrypted']
  },
  {
    id: 'crypto',
    name: 'Polygon / USDT Web3',
    subtitle: 'Decentralized • Multi-Sig Escrow',
    badge: 'Sub-Cent Gas',
    badgeBg: 'rgba(255, 193, 7, 0.2)',
    badgeColor: 'var(--color-attention-yellow)',
    accentColor: 'var(--color-attention-yellow)',
    icon: 'currency_bitcoin',
    description: 'Decentralized on-chain payment. Send USDT or POL directly to the open-source compute escrow vault.',
    features: ['Polygon PoS (< $0.005 gas)', 'Instant on-chain settlement', 'Direct multi-sig vault']
  }
];

export interface PaymentLocationState {
  amount?: number;
  tierName?: string;
  paymentMethod?: PaymentMethodId;
  paymentMethodTitle?: string;
  referenceId?: string;
  message?: string;
  phone?: string;
}
