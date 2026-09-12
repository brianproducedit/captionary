/** Public client configuration. Never put payment Integration IDs, API keys, or R2 upload secrets here. */
export const publicConfig = {
  donateWebUrl: 'https://captionary.co.zw/donate',
  /** Set to a public Ko-fi page when one exists. Empty = rail disabled. */
  kofiUrl: '',
  /** Set to a public Buy Me a Coffee page when one exists. Empty = rail disabled. */
  bmcUrl: '',
  /** Hosted Paynow checkout URL only — never an Integration ID/Key. Empty = rail disabled. */
  paynowUrl: '',
  /** Public receive address only. Empty = crypto rail disabled. */
  cryptoAddress: '',
  cryptoNetwork: 'Polygon (USDT/USDC)',
  licenseUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
} as const;
