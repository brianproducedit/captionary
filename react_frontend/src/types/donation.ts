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
    description:
      'Helps cover Cloudflare R2 regional model chunk downloads for mobile clients in low-bandwidth areas.',
  },
  {
    id: 'starter',
    name: 'Dialect Starter',
    badge: 'Lexicon Boost',
    amount: 5,
    icon: 'menu_book',
    description:
      'Supports phoneme dictionary work and vocabulary expansion for under-resourced regional dialects.',
  },
  {
    id: 'language',
    name: 'Language Champion',
    badge: '★ Popular',
    amount: 10,
    icon: 'translate',
    description:
      'Helps fund targeted compute for regional African dialect weights (Shona, isiZulu, Sepedi).',
    popular: true,
  },
  {
    id: 'architect',
    name: 'Model Architect',
    badge: 'Quantization',
    amount: 25,
    icon: 'memory',
    description:
      'Helps cover edge ONNX/CoreML quantization runs and transcription quality benchmarking.',
  },
  {
    id: 'pillar',
    name: 'Ecosystem Pillar',
    badge: 'Patron',
    amount: 50,
    icon: 'workspace_premium',
    description:
      'Helps fund community voice recording stipends and independent dialect preservation grants.',
  },
];

export type PaymentMethodId = 'kofi' | 'bmc' | 'paynow' | 'crypto';

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
    id: 'kofi',
    name: 'Ko-fi',
    subtitle: 'Public tip page',
    badge: 'External',
    badgeBg: 'rgba(33, 150, 243, 0.2)',
    badgeColor: 'var(--color-primary)',
    accentColor: 'var(--color-primary)',
    icon: 'local_cafe',
    description:
      'Opens the public Ko-fi page in a new tab. Captionary never sees your card.',
    features: ['External checkout', 'No Captionary payment API'],
  },
  {
    id: 'bmc',
    name: 'Buy Me a Coffee',
    subtitle: 'Public tip page',
    badge: 'External',
    badgeBg: 'rgba(255, 193, 7, 0.2)',
    badgeColor: 'var(--color-attention-yellow)',
    accentColor: 'var(--color-attention-yellow)',
    icon: 'coffee',
    description: 'Opens the public Buy Me a Coffee page in a new tab.',
    features: ['External checkout', 'No Captionary payment API'],
  },
  {
    id: 'paynow',
    name: 'Paynow hosted page',
    subtitle: 'Zimbabwe • hosted checkout only',
    badge: 'Hosted URL',
    badgeBg: 'rgba(66, 165, 71, 0.2)',
    badgeColor: 'var(--color-tertiary)',
    accentColor: 'var(--color-tertiary)',
    icon: 'payments',
    description:
      'Uses a public Paynow-hosted checkout URL if one is configured. No Integration ID or key in this app.',
    features: ['Hosted page only', 'Disabled until a public URL exists'],
  },
  {
    id: 'crypto',
    name: 'Crypto address',
    subtitle: 'Public receive address',
    badge: 'Copy',
    badgeBg: 'rgba(134, 3, 156, 0.25)',
    badgeColor: 'var(--color-secondary)',
    accentColor: 'var(--color-secondary)',
    icon: 'currency_bitcoin',
    description:
      'Copy a published receive address. Disabled until an address is set in public config.',
    features: ['Address only', 'No on-site confirmation'],
  },
];

export interface PaymentLocationState {
  amount?: number;
  tierName?: string;
  paymentMethod?: PaymentMethodId;
  paymentMethodTitle?: string;
  message?: string;
  pendingExternal?: boolean;
  instructions?: string;
}
