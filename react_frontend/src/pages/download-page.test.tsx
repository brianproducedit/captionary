import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { DownloadPage } from './DownloadPage';
import * as releaseService from '../services/githubRelease';

describe('DownloadPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('renders download hero, badges, and primary universal download button', async () => {
    render(
      <MemoryRouter>
        <DownloadPage />
      </MemoryRouter>
    );

    // Hero title
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(/Download Captionary/i);

    // Platform badge
    expect(screen.getByText(/Android Mobile App/i)).toBeInTheDocument();

    // Universal APK Primary Action
    expect(screen.getByText(/Download Universal APK/i)).toBeInTheDocument();

    // Architecture cards
    await waitFor(() => {
      expect(screen.getAllByText(/Universal APK/i).length).toBeGreaterThan(0);
      expect(screen.getByText(/ARM64-v8a APK/i)).toBeInTheDocument();
      expect(screen.getByText(/ARMv7a \(32-bit\) APK/i)).toBeInTheDocument();
      expect(screen.getByText(/x86_64 APK/i)).toBeInTheDocument();
    });
  });

  it('switches between All APKs, Installation Guide, and Hardware Specs tabs', async () => {
    render(
      <MemoryRouter>
        <DownloadPage />
      </MemoryRouter>
    );

    // Switch to Installation Guide
    const guideTabs = screen.getAllByRole('button', { name: /Installation Guide/i });
    fireEvent.click(guideTabs[0]);

    expect(screen.getByText(/How to Install Captionary APK on Android/i)).toBeInTheDocument();
    expect(screen.getByText(/Download the APK/i)).toBeInTheDocument();
    expect(screen.getByText(/Allow Unknown Sources/i)).toBeInTheDocument();

    // Switch to Hardware Specs
    const specsTabs = screen.getAllByRole('button', { name: /Device Specs & RAM/i });
    fireEvent.click(specsTabs[0]);

    expect(screen.getByText(/Hardware Specs & Memory Tiering/i)).toBeInTheDocument();
    expect(screen.getByText(/Low RAM Tier/i)).toBeInTheDocument();
    expect(screen.getByText(/Standard Tier/i)).toBeInTheDocument();
    expect(screen.getByText(/High Tier/i)).toBeInTheDocument();
  });

  it('handles live release data correctly from release service', async () => {
    vi.spyOn(releaseService, 'fetchLatestRelease').mockResolvedValueOnce({
      version: '1.2.0',
      tagName: 'v1.2.0',
      name: 'Captionary v1.2.0',
      publishedAt: '2026-09-17T08:00:00Z',
      publishedFormatted: 'Sep 17, 2026',
      htmlUrl: 'https://github.com/brianproducedit/captionary/releases/tag/v1.2.0',
      body: 'Test release body',
      isPrerelease: false,
      source: 'live',
      assets: {
        universal: {
          name: 'app-release.apk',
          downloadUrl: 'https://example.com/app-release.apk',
          size: 80000000,
          sizeFormatted: '76.3 MB',
          downloadCount: 42,
          abi: 'universal',
          label: 'Universal APK',
          description: 'All devices',
        },
        all: [],
      },
    });

    render(
      <MemoryRouter>
        <DownloadPage />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('v1.2.0')).toBeInTheDocument();
      expect(screen.getByText(/Live GitHub Releases/i)).toBeInTheDocument();
    });
  });
});
