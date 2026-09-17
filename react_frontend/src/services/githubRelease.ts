import { publicConfig } from '../config/public';

export type ApkAbi = 'universal' | 'arm64-v8a' | 'armeabi-v7a' | 'x86_64' | 'checksums' | 'metadata' | 'other';

export interface ReleaseAsset {
  name: string;
  downloadUrl: string;
  size: number;
  sizeFormatted: string;
  downloadCount: number;
  abi: ApkAbi;
  label: string;
  description: string;
}

export interface GitHubReleaseInfo {
  version: string;
  tagName: string;
  name: string;
  publishedAt: string;
  publishedFormatted: string;
  htmlUrl: string;
  body: string;
  isPrerelease: boolean;
  assets: {
    universal?: ReleaseAsset;
    arm64?: ReleaseAsset;
    arm32?: ReleaseAsset;
    x86_64?: ReleaseAsset;
    checksums?: ReleaseAsset;
    all: ReleaseAsset[];
  };
  source: 'live' | 'cache' | 'fallback';
}

const CACHE_KEY = 'captionary_latest_release';
const CACHE_TTL_MS = 15 * 60 * 1000; // 15 minutes

export function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return 'Unknown size';
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return `${size.toFixed(1)} ${units[unitIndex]}`;
}

export function formatReleaseDate(isoString: string): string {
  try {
    const date = new Date(isoString);
    if (isNaN(date.getTime())) return 'Recently';
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return 'Recently';
  }
}

function detectAbi(filename: string): ApkAbi {
  const lower = filename.toLowerCase();
  if (lower.includes('arm64-v8a')) return 'arm64-v8a';
  if (lower.includes('armeabi-v7a') || lower.includes('arm-v7a')) return 'armeabi-v7a';
  if (lower.includes('x86_64') || lower.includes('x64')) return 'x86_64';
  if (lower.endsWith('.apk') && (lower.includes('app-release') || lower.includes('universal') || !lower.includes('v8a'))) {
    return 'universal';
  }
  if (lower.includes('sha256') || lower.endsWith('.txt')) return 'checksums';
  if (lower.endsWith('.json')) return 'metadata';
  return 'other';
}

function getAbiLabel(abi: ApkAbi): string {
  switch (abi) {
    case 'universal':
      return 'Universal APK (Recommended)';
    case 'arm64-v8a':
      return 'ARM64-v8a (64-bit)';
    case 'armeabi-v7a':
      return 'ARMv7a (32-bit)';
    case 'x86_64':
      return 'x86_64 (Emulators/PC)';
    case 'checksums':
      return 'SHA256 Checksums';
    case 'metadata':
      return 'Release Metadata';
    default:
      return 'Release Asset';
  }
}

function getAbiDescription(abi: ApkAbi): string {
  switch (abi) {
    case 'universal':
      return 'Works on 100% of Android devices. All CPU architectures included in one package.';
    case 'arm64-v8a':
      return 'Recommended for modern phones (2017+). Reduced file size and optimized 64-bit performance.';
    case 'armeabi-v7a':
      return 'For older 32-bit Android phones and legacy entry-level hardware.';
    case 'x86_64':
      return 'For Android emulators, ChromeOS devices, and Intel tablets.';
    case 'checksums':
      return 'SHA256 checksums to verify cryptographic integrity of downloaded APKs.';
    case 'metadata':
      return 'Machine-readable JSON specification of release artifacts.';
    default:
      return 'Additional release artifact.';
  }
}

const HARDCODED_FALLBACK: GitHubReleaseInfo = {
  version: publicConfig.defaultVersion,
  tagName: `v${publicConfig.defaultVersion}`,
  name: `Captionary v${publicConfig.defaultVersion}`,
  publishedAt: new Date().toISOString(),
  publishedFormatted: 'Latest Release',
  htmlUrl: publicConfig.githubReleasesUrl,
  body: 'Offline-first AI Speech Captioning Studio for Android.\n- Pure on-device Whisper AI\n- Styled ASS & SRT subtitle burn-in\n- Zero cloud telemetry',
  isPrerelease: false,
  source: 'fallback',
  assets: {
    universal: {
      name: 'app-release.apk',
      downloadUrl: `${publicConfig.githubReleasesUrl}/latest/download/app-release.apk`,
      size: 83886080,
      sizeFormatted: '~80 MB',
      downloadCount: 0,
      abi: 'universal',
      label: 'Universal APK (Recommended)',
      description: 'Works on 100% of Android devices. All CPU architectures included in one package.',
    },
    arm64: {
      name: 'app-arm64-v8a-release.apk',
      downloadUrl: `${publicConfig.githubReleasesUrl}/latest/download/app-arm64-v8a-release.apk`,
      size: 47185920,
      sizeFormatted: '~45 MB',
      downloadCount: 0,
      abi: 'arm64-v8a',
      label: 'ARM64-v8a (64-bit)',
      description: 'Recommended for modern phones (2017+). Reduced file size and optimized 64-bit performance.',
    },
    arm32: {
      name: 'app-armeabi-v7a-release.apk',
      downloadUrl: `${publicConfig.githubReleasesUrl}/latest/download/app-armeabi-v7a-release.apk`,
      size: 41943040,
      sizeFormatted: '~40 MB',
      downloadCount: 0,
      abi: 'armeabi-v7a',
      label: 'ARMv7a (32-bit)',
      description: 'For older 32-bit Android phones and legacy entry-level hardware.',
    },
    x86_64: {
      name: 'app-x86_64-release.apk',
      downloadUrl: `${publicConfig.githubReleasesUrl}/latest/download/app-x86_64-release.apk`,
      size: 50331648,
      sizeFormatted: '~48 MB',
      downloadCount: 0,
      abi: 'x86_64',
      label: 'x86_64 (Emulators/PC)',
      description: 'For Android emulators, ChromeOS devices, and Intel tablets.',
    },
    checksums: {
      name: 'SHA256SUMS.txt',
      downloadUrl: `${publicConfig.githubReleasesUrl}/latest/download/SHA256SUMS.txt`,
      size: 512,
      sizeFormatted: '< 1 KB',
      downloadCount: 0,
      abi: 'checksums',
      label: 'SHA256 Checksums',
      description: 'SHA256 checksums to verify cryptographic integrity of downloaded APKs.',
    },
    all: [],
  },
};

HARDCODED_FALLBACK.assets.all = [
  HARDCODED_FALLBACK.assets.universal!,
  HARDCODED_FALLBACK.assets.arm64!,
  HARDCODED_FALLBACK.assets.arm32!,
  HARDCODED_FALLBACK.assets.x86_64!,
  HARDCODED_FALLBACK.assets.checksums!,
];

export async function fetchLatestRelease(options: { forceRefresh?: boolean } = {}): Promise<GitHubReleaseInfo> {
  const { forceRefresh = false } = options;

  // 1. Check client session storage cache unless forced
  if (!forceRefresh && typeof window !== 'undefined' && window.sessionStorage) {
    try {
      const cachedRaw = window.sessionStorage.getItem(CACHE_KEY);
      if (cachedRaw) {
        const parsed = JSON.parse(cachedRaw);
        if (parsed.timestamp && Date.now() - parsed.timestamp < CACHE_TTL_MS && parsed.data) {
          return {
            ...parsed.data,
            source: 'cache',
          };
        }
      }
    } catch {
      // Ignore cache read errors
    }
  }

  // 2. Query Cloudflare R2 / GitHub Releases REST API
  try {
    const res = await fetch(publicConfig.latestReleaseApiUrl, {
      headers: {
        Accept: 'application/json, application/vnd.github.v3+json',
      },
    });

    if (res.ok) {
      const data = await res.json();
      const rawAssets: any[] = Array.isArray(data.assets) ? data.assets : [];

      const parsedAssets: ReleaseAsset[] = rawAssets.map((asset: any) => {
        const abi = (asset.abi as ApkAbi) || detectAbi(asset.name || '');
        return {
          name: asset.name || 'unnamed-asset',
          downloadUrl: asset.downloadUrl || asset.browser_download_url || `${publicConfig.r2PublicBaseUrl}/${asset.name}`,
          size: asset.size || 0,
          sizeFormatted: formatBytes(asset.size || 0),
          downloadCount: asset.download_count || asset.downloadCount || 0,
          abi,
          label: asset.label || getAbiLabel(abi),
          description: asset.description || getAbiDescription(abi),
        };
      });

      const universal = parsedAssets.find((a) => a.abi === 'universal');
      const arm64 = parsedAssets.find((a) => a.abi === 'arm64-v8a');
      const arm32 = parsedAssets.find((a) => a.abi === 'armeabi-v7a');
      const x86_64 = parsedAssets.find((a) => a.abi === 'x86_64');
      const checksums = parsedAssets.find((a) => a.abi === 'checksums');

      const rawTag: string = data.tagName || data.tag_name || `v${publicConfig.defaultVersion}`;
      const cleanVersion = data.version || (rawTag.startsWith('v') ? rawTag.slice(1) : rawTag);

      const releaseInfo: GitHubReleaseInfo = {
        version: cleanVersion,
        tagName: rawTag,
        name: data.name || `Captionary ${rawTag}`,
        publishedAt: data.publishedAt || data.published_at || new Date().toISOString(),
        publishedFormatted: formatReleaseDate(data.publishedAt || data.published_at || ''),
        htmlUrl: data.htmlUrl || data.html_url || publicConfig.githubReleasesUrl,
        body: data.body || '',
        isPrerelease: !!data.prerelease || !!data.isPrerelease,
        assets: {
          universal: universal || HARDCODED_FALLBACK.assets.universal,
          arm64: arm64 || HARDCODED_FALLBACK.assets.arm64,
          arm32: arm32 || HARDCODED_FALLBACK.assets.arm32,
          x86_64: x86_64 || HARDCODED_FALLBACK.assets.x86_64,
          checksums: checksums || HARDCODED_FALLBACK.assets.checksums,
          all: parsedAssets.length > 0 ? parsedAssets : HARDCODED_FALLBACK.assets.all,
        },
        source: 'live',
      };

      // Save to sessionStorage
      if (typeof window !== 'undefined' && window.sessionStorage) {
        try {
          window.sessionStorage.setItem(
            CACHE_KEY,
            JSON.stringify({
              timestamp: Date.now(),
              data: releaseInfo,
            })
          );
        } catch {
          // Ignore cache write errors
        }
      }

      return releaseInfo;
    }
  } catch {
    // Network / CORS / rate-limit failure -> proceed to static fallback
  }

  // 3. Fallback: Try static public/latest-release.json
  try {
    const staticRes = await fetch('/latest-release.json');
    if (staticRes.ok) {
      const staticData = await staticRes.json();
      const assets: ReleaseAsset[] = (staticData.assets || []).map((a: any) => ({
        name: a.name,
        downloadUrl: a.downloadUrl,
        size: a.size || 0,
        sizeFormatted: formatBytes(a.size || 0),
        downloadCount: 0,
        abi: a.abi as ApkAbi,
        label: a.label || getAbiLabel(a.abi),
        description: a.description || getAbiDescription(a.abi),
      }));

      return {
        version: staticData.version || publicConfig.defaultVersion,
        tagName: staticData.tagName || `v${publicConfig.defaultVersion}`,
        name: staticData.name || `Captionary v${publicConfig.defaultVersion}`,
        publishedAt: staticData.publishedAt || new Date().toISOString(),
        publishedFormatted: formatReleaseDate(staticData.publishedAt || ''),
        htmlUrl: staticData.htmlUrl || publicConfig.githubReleasesUrl,
        body: staticData.body || '',
        isPrerelease: false,
        assets: {
          universal: assets.find((a) => a.abi === 'universal') || HARDCODED_FALLBACK.assets.universal,
          arm64: assets.find((a) => a.abi === 'arm64-v8a') || HARDCODED_FALLBACK.assets.arm64,
          arm32: assets.find((a) => a.abi === 'armeabi-v7a') || HARDCODED_FALLBACK.assets.arm32,
          x86_64: assets.find((a) => a.abi === 'x86_64') || HARDCODED_FALLBACK.assets.x86_64,
          checksums: assets.find((a) => a.abi === 'checksums') || HARDCODED_FALLBACK.assets.checksums,
          all: assets.length > 0 ? assets : HARDCODED_FALLBACK.assets.all,
        },
        source: 'fallback',
      };
    }
  } catch {
    // Ignore static fetch error
  }

  // 4. Ultimate offline hardcoded fallback
  return HARDCODED_FALLBACK;
}
