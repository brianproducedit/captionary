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
  licenseUrl: 'https://captionary.co.zw/terms',
  githubRepo: 'brianproducedit/captionary',
  githubUrl: 'https://github.com/brianproducedit/captionary',
  githubReleasesUrl: 'https://captionary.co.zw/download',
  r2PublicBaseUrl: 'https://pub-6315c0ddbd0d44b4856162c00e47e86e.r2.dev/apks',
  latestReleaseApiUrl: 'https://pub-6315c0ddbd0d44b4856162c00e47e86e.r2.dev/apks/latest-release.json',
  defaultVersion: '1.0.1',
  minAndroidVersion: 'Android 8.0+ (API 26)',
  recommendedRam: '4 GB+ RAM',
} as const;
