import React, { useEffect, useState } from 'react';
import { publicConfig } from '../config/public';
import { fetchLatestRelease, type GitHubReleaseInfo, type ApkAbi } from '../services/githubRelease';
import { MaterialIcon } from '../components/MaterialIcon';

export const DownloadPage: React.FC = () => {
  const [release, setRelease] = useState<GitHubReleaseInfo | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [copiedChecksum, setCopiedChecksum] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'all' | 'guide' | 'hardware'>('all');

  const loadReleaseData = async (force = false) => {
    if (force) setRefreshing(true);
    try {
      const data = await fetchLatestRelease({ forceRefresh: force });
      setRelease(data);
    } catch {
      // Release service handles fallbacks internally
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let ignore = false;
    fetchLatestRelease({ forceRefresh: false }).then((data) => {
      if (!ignore) {
        setRelease(data);
        setLoading(false);
      }
    });
    return () => {
      ignore = true;
    };
  }, []);

  const handleCopy = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedChecksum(id);
    setTimeout(() => setCopiedChecksum(null), 2500);
  };

  const universalAsset = release?.assets.universal;
  const arm64Asset = release?.assets.arm64;
  const arm32Asset = release?.assets.arm32;
  const x86Asset = release?.assets.x86_64;

  const getStatusBadge = () => {
    if (loading && !release) {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border animate-pulse"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                color: 'var(--color-on-surface-variant)',
                borderColor: 'rgba(255, 255, 255, 0.1)',
              }}>
          <MaterialIcon icon="sync" className="text-sm animate-spin" />
          Checking Releases...
        </span>
      );
    }
    if (!release) return null;
    if (release.source === 'live') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border"
              style={{
                backgroundColor: 'rgba(66, 165, 71, 0.15)',
                color: 'var(--color-tertiary)',
                borderColor: 'rgba(66, 165, 71, 0.35)',
              }}>
          <span className="w-2 h-2 rounded-full animate-pulse" style={{ backgroundColor: 'var(--color-tertiary)' }} />
          Live GitHub Releases
        </span>
      );
    }
    if (release.source === 'cache') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border"
              style={{
                backgroundColor: 'rgba(33, 150, 243, 0.15)',
                color: 'var(--color-primary)',
                borderColor: 'rgba(33, 150, 243, 0.35)',
              }}>
          <MaterialIcon icon="cached" className="text-sm" />
          Cached Release Data
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border"
            style={{
              backgroundColor: 'rgba(255, 193, 7, 0.15)',
              color: 'var(--color-attention-yellow)',
              borderColor: 'rgba(255, 193, 7, 0.35)',
            }}>
        <MaterialIcon icon="offline_bolt" className="text-sm" />
        Offline Release Mirror
      </span>
    );
  };

  return (
    <div className="max-w-7xl mx-auto py-10"
         style={{
           paddingLeft: 'var(--spacing-margin-mobile)',
           paddingRight: 'var(--spacing-margin-mobile)',
         }}>
      {/* Hero Section */}
      <section className="relative overflow-hidden rounded-3xl border text-center p-8 sm:p-14 mb-12"
               style={{
                 backgroundColor: 'var(--color-surface-container-lowest)',
                 borderColor: 'rgba(64, 71, 82, 0.4)',
                 boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)',
               }}>
        {/* Glow ambient effects */}
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 w-96 h-96 rounded-full blur-3xl opacity-20 pointer-events-none"
             style={{ background: 'radial-gradient(circle, #2196f3 0%, #86039c 100%)' }} />

        <div className="relative z-10 flex flex-col items-center max-w-3xl mx-auto">
          {/* Header Badges */}
          <div className="flex flex-wrap items-center justify-center gap-3 mb-6">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wider"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: 'var(--color-on-surface-variant)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                  }}>
              <MaterialIcon icon="android" className="text-sm" style={{ color: 'var(--color-tertiary)' }} />
              Android Mobile App
            </span>
            {getStatusBadge()}
            {release && (
              <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold"
                    style={{
                      backgroundColor: 'rgba(158, 202, 255, 0.15)',
                      color: 'var(--color-primary)',
                      border: '1px solid rgba(158, 202, 255, 0.3)',
                    }}>
                v{release.version}
              </span>
            )}
          </div>

          <h1 className="text-3xl sm:text-5xl font-bold tracking-tight mb-4"
              style={{
                fontFamily: 'var(--font-display)',
                color: 'var(--color-on-surface)',
                lineHeight: 1.15,
              }}>
            Download <span className="bg-gradient-to-r from-blue-400 via-indigo-300 to-purple-400 bg-clip-text text-transparent">Captionary</span>
          </h1>

          <p className="text-base sm:text-lg text-gray-300 max-w-2xl mb-8 leading-relaxed"
             style={{ color: 'var(--color-on-surface-variant)' }}>
            On-device AI speech captioning and video subtitling studio for African creators.
            100% offline, privacy-first, with zero cloud uploads and zero telemetry.
          </p>

          {/* Primary Action Button */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full max-w-md">
            <a
              href={universalAsset?.downloadUrl || `${publicConfig.githubReleasesUrl}/latest/download/app-release.apk`}
              download
              className="w-full sm:w-auto flex-1 flex items-center justify-center gap-3 px-8 py-4 rounded-full font-semibold transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] shadow-lg"
              style={{
                backgroundImage: 'linear-gradient(to right, var(--color-primary-container), var(--color-secondary-container))',
                color: 'var(--color-on-primary)',
                boxShadow: '0 8px 24px rgba(33, 150, 243, 0.35)',
              }}
            >
              <MaterialIcon icon="download" className="text-2xl" />
              <div className="flex flex-col text-left">
                <span className="text-sm font-bold">Download Universal APK</span>
                <span className="text-xs opacity-90">
                  {universalAsset?.sizeFormatted || '~80 MB'} · Works on all Android phones
                </span>
              </div>
            </a>

            <button
              onClick={() => loadReleaseData(true)}
              disabled={refreshing}
              title="Check for latest release updates"
              className="flex items-center justify-center p-4 rounded-full border transition-colors hover:bg-gray-800"
              style={{
                borderColor: 'rgba(64, 71, 82, 0.5)',
                backgroundColor: 'var(--color-surface-container-high)',
                color: 'var(--color-on-surface-variant)',
              }}
            >
              <MaterialIcon icon="refresh" className={`text-xl ${refreshing ? 'animate-spin' : ''}`} />
            </button>
          </div>

          {/* Sub-meta */}
          <div className="flex flex-wrap items-center justify-center gap-6 mt-6 text-xs text-gray-400">
            <span className="inline-flex items-center gap-1.5">
              <MaterialIcon icon="security" className="text-sm" style={{ color: 'var(--color-tertiary)' }} />
              AGPL-3.0 Open Source
            </span>
            <span className="inline-flex items-center gap-1.5">
              <MaterialIcon icon="phonelink_setup" className="text-sm" style={{ color: 'var(--color-primary)' }} />
              Requires {publicConfig.minAndroidVersion}
            </span>
            <span className="inline-flex items-center gap-1.5">
              <MaterialIcon icon="memory" className="text-sm" style={{ color: 'var(--color-secondary)' }} />
              {publicConfig.recommendedRam}
            </span>
          </div>
        </div>
      </section>

      {/* Navigation Tabs */}
      <div className="flex items-center justify-center gap-2 mb-8 overflow-x-auto pb-2">
        {[
          { id: 'all', label: 'All APK Downloads', icon: 'apps' },
          { id: 'guide', label: 'Installation Guide', icon: 'help_outline' },
          { id: 'hardware', label: 'Device Specs & RAM', icon: 'speed' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className="flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-medium transition-all"
            style={{
              backgroundColor: activeTab === tab.id ? 'var(--color-surface-container-highest)' : 'var(--color-surface-container-low)',
              color: activeTab === tab.id ? 'var(--color-on-surface)' : 'var(--color-on-surface-variant)',
              border: '1px solid',
              borderColor: activeTab === tab.id ? 'rgba(158, 202, 255, 0.4)' : 'rgba(64, 71, 82, 0.3)',
            }}
          >
            <MaterialIcon icon={tab.icon} className="text-base" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* TAB 1: ALL APKs */}
      {activeTab === 'all' && (
        <div className="space-y-8">
          {/* APK Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Card 1: Universal */}
            <ApkCard
              title="Universal APK"
              badge="Recommended"
              badgeColor="var(--color-primary)"
              size={universalAsset?.sizeFormatted || '~80 MB'}
              description="Single install file that contains all native libraries. Guaranteed to run on any compatible Android device."
              downloadUrl={universalAsset?.downloadUrl || `${publicConfig.githubReleasesUrl}/latest/download/app-release.apk`}
              fileName={universalAsset?.name || 'app-release.apk'}
              abi="universal"
              isPrimary
            />

            {/* Card 2: ARM64-v8a */}
            <ApkCard
              title="ARM64-v8a APK"
              badge="Smallest for Modern Phones"
              badgeColor="var(--color-tertiary)"
              size={arm64Asset?.sizeFormatted || '~45 MB'}
              description="Optimized specifically for 64-bit ARM processors. Saves ~45% download data compared to the universal package."
              downloadUrl={arm64Asset?.downloadUrl || `${publicConfig.githubReleasesUrl}/latest/download/app-arm64-v8a-release.apk`}
              fileName={arm64Asset?.name || 'app-arm64-v8a-release.apk'}
              abi="arm64-v8a"
            />

            {/* Card 3: ARMv7a */}
            <ApkCard
              title="ARMv7a (32-bit) APK"
              badge="Legacy Devices"
              badgeColor="var(--color-warm-coral)"
              size={arm32Asset?.sizeFormatted || '~40 MB'}
              description="For older Android phones or budget devices built with 32-bit ARM processors."
              downloadUrl={arm32Asset?.downloadUrl || `${publicConfig.githubReleasesUrl}/latest/download/app-armeabi-v7a-release.apk`}
              fileName={arm32Asset?.name || 'app-armeabi-v7a-release.apk'}
              abi="armeabi-v7a"
            />

            {/* Card 4: x86_64 */}
            <ApkCard
              title="x86_64 APK"
              badge="Emulators & ChromeOS"
              badgeColor="var(--color-secondary)"
              size={x86Asset?.sizeFormatted || '~48 MB'}
              description="For Android Studio emulators, ChromeOS Chromebooks, and Intel/AMD PC hardware running Android."
              downloadUrl={x86Asset?.downloadUrl || `${publicConfig.githubReleasesUrl}/latest/download/app-x86_64-release.apk`}
              fileName={x86Asset?.name || 'app-x86_64-release.apk'}
              abi="x86_64"
            />
          </div>

          {/* Cryptographic Verification Card */}
          <div className="rounded-2xl border p-6 sm:p-8"
               style={{
                 backgroundColor: 'var(--color-surface-container-low)',
                 borderColor: 'rgba(64, 71, 82, 0.3)',
               }}>
            <div className="flex items-center gap-3 mb-4">
              <MaterialIcon icon="verified_user" className="text-2xl" style={{ color: 'var(--color-tertiary)' }} />
              <div>
                <h3 className="text-lg font-bold" style={{ color: 'var(--color-on-surface)' }}>
                  Cryptographic Integrity & SHA256 Checksums
                </h3>
                <p className="text-xs sm:text-sm" style={{ color: 'var(--color-on-surface-variant)' }}>
                  Verify that your downloaded APK has not been tampered with or corrupted.
                </p>
              </div>
            </div>

            <div className="rounded-xl p-4 font-mono text-xs overflow-x-auto border flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                 style={{
                   backgroundColor: 'var(--color-base-canvas)',
                   borderColor: 'rgba(64, 71, 82, 0.4)',
                   color: 'var(--color-primary-fixed-dim)',
                 }}>
              <span className="truncate">
                sha256sum -c SHA256SUMS.txt
              </span>
              <div className="flex items-center gap-2 shrink-0">
                <button
                  type="button"
                  onClick={() => handleCopy('sha256sum -c SHA256SUMS.txt', 'cmd')}
                  className="px-3 py-1.5 rounded text-xs font-sans font-medium transition-colors hover:bg-gray-800 flex items-center gap-1.5"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: copiedChecksum === 'cmd' ? 'var(--color-tertiary)' : 'var(--color-on-surface)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                  }}
                >
                  <MaterialIcon icon={copiedChecksum === 'cmd' ? 'check' : 'content_copy'} className="text-sm" />
                  {copiedChecksum === 'cmd' ? 'Copied' : 'Copy Command'}
                </button>
                <a
                  href={`${publicConfig.githubReleasesUrl}/latest/download/SHA256SUMS.txt`}
                  download
                  className="px-3 py-1.5 rounded text-xs font-sans font-medium transition-colors hover:bg-gray-800"
                  style={{
                    backgroundColor: 'var(--color-surface-container-high)',
                    color: 'var(--color-on-surface)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                  }}
                >
                  Download SHA256SUMS.txt
                </a>
              </div>
            </div>
          </div>

          {/* Open Source Transparency Banner */}
          <div className="rounded-2xl border p-6 flex flex-col md:flex-row items-center justify-between gap-6"
               style={{
                 backgroundColor: 'var(--color-surface-container-lowest)',
                 borderColor: 'rgba(64, 71, 82, 0.3)',
               }}>
            <div className="flex items-start gap-4">
              <div className="p-3 rounded-xl shrink-0" style={{ backgroundColor: 'var(--color-surface-container-high)' }}>
                <MaterialIcon icon="code" className="text-2xl" style={{ color: 'var(--color-primary)' }} />
              </div>
              <div>
                <h4 className="font-semibold text-base mb-1" style={{ color: 'var(--color-on-surface)' }}>
                  Why Direct APK Instead of Google Play?
                </h4>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--color-on-surface-variant)' }}>
                  Captionary is a community-driven, privacy-first open-source initiative. As an independent developer,
                  we distribute APKs directly through GitHub Releases so you get instant updates without platform fees or surveillance.
                </p>
              </div>
            </div>

            <a
              href={publicConfig.githubUrl}
              target="_blank"
              rel="noreferrer"
              className="shrink-0 px-5 py-2.5 rounded-full border text-sm font-medium transition-colors hover:bg-gray-800 flex items-center gap-2"
              style={{
                backgroundColor: 'var(--color-surface-container-high)',
                color: 'var(--color-on-surface)',
                borderColor: 'rgba(64, 71, 82, 0.5)',
              }}
            >
              <MaterialIcon icon="open_in_new" className="text-base" />
              View Source on GitHub
            </a>
          </div>
        </div>
      )}

      {/* TAB 2: INSTALLATION GUIDE */}
      {activeTab === 'guide' && (
        <div className="rounded-2xl border p-6 sm:p-10"
             style={{
               backgroundColor: 'var(--color-surface-container-low)',
               borderColor: 'rgba(64, 71, 82, 0.3)',
             }}>
          <h2 className="text-2xl font-bold mb-2" style={{ color: 'var(--color-on-surface)' }}>
            How to Install Captionary APK on Android
          </h2>
          <p className="text-sm mb-8" style={{ color: 'var(--color-on-surface-variant)' }}>
            Installing an APK file ("sideloading") is safe and standard on Android. Follow these 4 simple steps:
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <GuideStep
              step="1"
              icon="download"
              title="Download the APK"
              description="Tap 'Download Universal APK' from your browser. When prompted with 'File might be harmful', tap 'Download anyway'."
            />
            <GuideStep
              step="2"
              icon="touch_app"
              title="Open the File"
              description="Open the downloaded APK directly from your browser's download tray or through your device's Files app."
            />
            <GuideStep
              step="3"
              icon="tune"
              title="Allow Unknown Sources"
              description="If prompted that your browser cannot install unknown apps, tap Settings and turn on 'Allow from this source'."
            />
            <GuideStep
              step="4"
              icon="rocket_launch"
              title="Install & Launch"
              description="Return to the installer, tap 'Install', and open Captionary. You're ready to caption videos offline!"
            />
          </div>

          <div className="mt-8 p-4 rounded-xl border flex items-center gap-3 text-xs"
               style={{
                 backgroundColor: 'rgba(255, 193, 7, 0.1)',
                 borderColor: 'rgba(255, 193, 7, 0.25)',
                 color: 'var(--color-on-surface)',
               }}>
            <MaterialIcon icon="info" className="text-lg shrink-0" style={{ color: 'var(--color-attention-yellow)' }} />
            <span>
              Google Play Protect may show a prompt saying "Unrecognized App". Tap <strong>"More Details"</strong> and then <strong>"Install anyway"</strong>.
              The app is 100% open source under the AGPL-3.0 license.
            </span>
          </div>
        </div>
      )}

      {/* TAB 3: HARDWARE & DEVICE SPECS */}
      {activeTab === 'hardware' && (
        <div className="rounded-2xl border p-6 sm:p-10"
             style={{
               backgroundColor: 'var(--color-surface-container-low)',
               borderColor: 'rgba(64, 71, 82, 0.3)',
             }}>
          <h2 className="text-2xl font-bold mb-2" style={{ color: 'var(--color-on-surface)' }}>
            Hardware Specs & Memory Tiering (B11)
          </h2>
          <p className="text-sm mb-8" style={{ color: 'var(--color-on-surface-variant)' }}>
            Captionary runs Whisper AI locally on your device. Our built-in RAM safety engine automatically tunes performance to your phone:
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <RamTierCard
              tier="Low RAM Tier"
              badge="< 4 GB RAM"
              badgeColor="var(--color-attention-yellow)"
              icon="battery_saver"
              specs="Entry-level devices (e.g. 2GB - 3GB)"
              features={[
                'Automatic memory safety guards prevent out-of-memory crashes',
                'Recommended model: Tiny (77 MB)',
                '30s sequential chunk processing',
                'Aggressive temporary cache cleanup',
              ]}
            />

            <RamTierCard
              tier="Standard Tier"
              badge="4 GB - 6 GB RAM"
              badgeColor="var(--color-primary)"
              icon="memory"
              specs="Most modern smartphones"
              features={[
                'Base model support for higher caption accuracy',
                'Hardware-accelerated video export & ASS burn-in',
                'Real-time subtitle styling and playback preview',
                'Concurrent audio extraction & timeline generation',
              ]}
              isHighlight
            />

            <RamTierCard
              tier="High Tier"
              badge="≥ 6 GB RAM"
              badgeColor="var(--color-tertiary)"
              icon="speed"
              specs="High-performance & flagship phones"
              features={[
                'Multi-threaded Whisper execution (4 threads)',
                'Rapid video transcription and styled burn-in',
                'Smooth 4K video preview and live waveform rendering',
                'Large offline language pack capacity',
              ]}
            />
          </div>
        </div>
      )}
    </div>
  );
};

interface ApkCardProps {
  title: string;
  badge: string;
  badgeColor: string;
  size: string;
  description: string;
  downloadUrl: string;
  fileName: string;
  abi: ApkAbi;
  isPrimary?: boolean;
}

const ApkCard: React.FC<ApkCardProps> = ({
  title,
  badge,
  badgeColor,
  size,
  description,
  downloadUrl,
  fileName,
  isPrimary = false,
}) => {
  return (
    <div className={`relative rounded-2xl border p-6 flex flex-col justify-between transition-all duration-200 ${isPrimary ? 'ring-1' : ''}`}
         style={{
           backgroundColor: isPrimary ? 'var(--color-surface-container)' : 'var(--color-surface-container-low)',
           borderColor: isPrimary ? 'rgba(33, 150, 243, 0.5)' : 'rgba(64, 71, 82, 0.3)',
           boxShadow: isPrimary ? '0 4px 20px rgba(33, 150, 243, 0.15)' : 'none',
         }}>
      <div>
        <div className="flex items-center justify-between gap-2 mb-3">
          <span className="text-xs font-semibold px-2.5 py-1 rounded-full border"
                style={{
                  color: badgeColor,
                  borderColor: `${badgeColor}40`,
                  backgroundColor: `${badgeColor}15`,
                }}>
            {badge}
          </span>
          <span className="text-xs font-mono text-gray-400">{size}</span>
        </div>

        <h3 className="text-xl font-bold mb-2" style={{ color: 'var(--color-on-surface)' }}>
          {title}
        </h3>

        <p className="text-sm leading-relaxed mb-6" style={{ color: 'var(--color-on-surface-variant)' }}>
          {description}
        </p>
      </div>

      <div className="flex items-center justify-between gap-4 pt-4 border-t"
           style={{ borderColor: 'rgba(64, 71, 82, 0.3)' }}>
        <span className="font-mono text-xs text-gray-400 truncate max-w-[160px] sm:max-w-[200px]" title={fileName}>
          {fileName}
        </span>

        <a
          href={downloadUrl}
          download
          className="flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all hover:scale-105"
          style={{
            backgroundColor: isPrimary ? 'var(--color-primary-container)' : 'var(--color-surface-container-high)',
            color: isPrimary ? 'var(--color-on-primary)' : 'var(--color-on-surface)',
            border: isPrimary ? 'none' : '1px solid rgba(255, 255, 255, 0.15)',
          }}
        >
          <MaterialIcon icon="download" className="text-base" />
          Download
        </a>
      </div>
    </div>
  );
};

interface GuideStepProps {
  step: string;
  icon: string;
  title: string;
  description: string;
}

const GuideStep: React.FC<GuideStepProps> = ({ step, icon, title, description }) => {
  return (
    <div className="rounded-xl border p-5 flex flex-col justify-between"
         style={{
           backgroundColor: 'var(--color-surface-container)',
           borderColor: 'rgba(64, 71, 82, 0.3)',
         }}>
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm"
               style={{
                 backgroundColor: 'var(--color-primary-container)',
                 color: 'var(--color-on-primary)',
               }}>
            {step}
          </div>
          <MaterialIcon icon={icon} className="text-xl" style={{ color: 'var(--color-on-surface-variant)' }} />
        </div>
        <h4 className="font-bold text-base mb-2" style={{ color: 'var(--color-on-surface)' }}>
          {title}
        </h4>
        <p className="text-xs sm:text-sm leading-relaxed" style={{ color: 'var(--color-on-surface-variant)' }}>
          {description}
        </p>
      </div>
    </div>
  );
};

interface RamTierCardProps {
  tier: string;
  badge: string;
  badgeColor: string;
  icon: string;
  specs: string;
  features: string[];
  isHighlight?: boolean;
}

const RamTierCard: React.FC<RamTierCardProps> = ({
  tier,
  badge,
  badgeColor,
  icon,
  specs,
  features,
  isHighlight = false,
}) => {
  return (
    <div className={`rounded-xl border p-6 flex flex-col justify-between ${isHighlight ? 'ring-1' : ''}`}
         style={{
           backgroundColor: 'var(--color-surface-container)',
           borderColor: isHighlight ? 'rgba(33, 150, 243, 0.5)' : 'rgba(64, 71, 82, 0.3)',
         }}>
      <div>
        <div className="flex items-center justify-between mb-4">
          <span className="text-xs font-semibold px-2.5 py-1 rounded-full border"
                style={{
                  color: badgeColor,
                  borderColor: `${badgeColor}40`,
                  backgroundColor: `${badgeColor}15`,
                }}>
            {badge}
          </span>
          <MaterialIcon icon={icon} className="text-2xl" style={{ color: badgeColor }} />
        </div>

        <h3 className="text-lg font-bold mb-1" style={{ color: 'var(--color-on-surface)' }}>
          {tier}
        </h3>
        <p className="text-xs text-gray-400 mb-4">{specs}</p>

        <ul className="space-y-2.5 text-xs sm:text-sm" style={{ color: 'var(--color-on-surface-variant)' }}>
          {features.map((feat, idx) => (
            <li key={idx} className="flex items-start gap-2">
              <MaterialIcon icon="check_circle" className="text-sm shrink-0 mt-0.5" style={{ color: badgeColor }} />
              <span>{feat}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};
