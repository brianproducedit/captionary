import { publicConfig } from '../config/public';
import type { PaymentMethodId } from '../types/donation';

export function isBrowserOnline(): boolean {
  return typeof navigator === 'undefined' ? true : navigator.onLine;
}

export function checkoutUrlFor(method: PaymentMethodId): string | undefined {
  switch (method) {
    case 'kofi':
      return publicConfig.kofiUrl || undefined;
    case 'bmc':
      return publicConfig.bmcUrl || undefined;
    case 'paynow':
      return publicConfig.paynowUrl || undefined;
    case 'crypto':
      return undefined;
  }
}

export function isMethodEnabled(method: PaymentMethodId): boolean {
  if (method === 'crypto') return Boolean(publicConfig.cryptoAddress);
  return Boolean(checkoutUrlFor(method));
}

export async function copyText(value: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(value);
    return true;
  } catch {
    return false;
  }
}

export function donationInstructions(amount: number, method: PaymentMethodId): string {
  const url = checkoutUrlFor(method);
  const parts = [
    `Captionary donation: $${amount} USD`,
    `Method: ${method}`,
  ];
  if (url) parts.push(`Checkout: ${url}`);
  if (method === 'crypto' && publicConfig.cryptoAddress) {
    parts.push(`${publicConfig.cryptoNetwork}: ${publicConfig.cryptoAddress}`);
  }
  if (!url && method !== 'crypto') {
    parts.push('No public checkout URL is configured for this rail yet.');
  }
  return parts.join('\n');
}
