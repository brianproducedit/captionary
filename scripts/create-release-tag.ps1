<#
.SYNOPSIS
    Bumps the Captionary mobile app version, commits, creates a git release tag, and pushes to trigger GitHub CI/CD.

.DESCRIPTION
    This script streamlines creating new releases for Captionary without a Google Play Developer account.
    Pushing the tag triggers .github/workflows/release.yml to build universal and split APKs, generate
    SHA256 checksums, and publish them to GitHub Releases for direct visitor download.

.PARAMETER Version
    The semver version string to release (e.g. 1.0.0). Do NOT prefix with 'v'.

.PARAMETER Push
    If specified, automatically pushes the commit and tag to GitHub origin.

.EXAMPLE
    .\scripts\create-release-tag.ps1 -Version 1.0.0
    .\scripts\create-release-tag.ps1 -Version 1.0.0 -Push
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the release version (e.g. 1.0.0):")]
    [string]$Version,

    [switch]$Push
)

$ErrorActionPreference = "Stop"

# Strip optional leading 'v'
$CleanVersion = $Version.TrimStart('v')
$Tag = "v$CleanVersion"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Captionary Release Tag Helper: $Tag" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Check git status
$Status = git status --porcelain
if ($Status) {
    Write-Warning "Working tree has uncommitted changes:"
    git status --short
    $Confirm = Read-Host "Do you want to proceed and include these changes in the release commit? (y/N)"
    if ($Confirm -ne 'y' -and $Confirm -ne 'Y') {
        Write-Host "Release aborted." -ForegroundColor Red
        exit 1
    }
}

# 2. Update flutter_mobile/pubspec.yaml version
$PubspecPath = "flutter_mobile/pubspec.yaml"
if (Test-Path $PubspecPath) {
    $Content = Get-Content $PubspecPath -Raw
    if ($Content -match 'version:\s*([0-9\.]+)\+?([0-9]*)') {
        $OldVersion = $Matches[1]
        $CurrentBuild = if ($Matches[2]) { [int]$Matches[2] } else { 1 }
        $NextBuild = $CurrentBuild + 1
        $NewVersionString = "version: $CleanVersion+$NextBuild"
        
        $UpdatedContent = $Content -replace 'version:\s*[0-9\.]+\+?[0-9]*', $NewVersionString
        Set-Content -Path $PubspecPath -Value $UpdatedContent -NoNewline
        Write-Host "[✓] Updated $PubspecPath : $OldVersion+$CurrentBuild -> $CleanVersion+$NextBuild" -ForegroundColor Green
    } else {
        Write-Warning "Could not find 'version:' pattern in $PubspecPath. Please check manually."
    }
}

# 3. Stage changes and commit
git add flutter_mobile/pubspec.yaml
if ($Status) {
    git add -A
}

$CommitMsg = "chore(release): $Tag"
git commit -m $CommitMsg
Write-Host "[✓] Created release commit: $CommitMsg" -ForegroundColor Green

# 4. Create annotated tag
git tag -a $Tag -m "Release $Tag"
Write-Host "[✓] Created git tag: $Tag" -ForegroundColor Green

# 5. Push if requested or display instructions
if ($Push) {
    Write-Host "Pushing main and $Tag to GitHub origin..." -ForegroundColor Yellow
    git push origin main
    git push origin $Tag
    Write-Host "[✓] Successfully pushed! GitHub Actions will now build release APKs." -ForegroundColor Green
    Write-Host "Track workflow: https://github.com/brianproducedit/captionary/actions" -ForegroundColor Cyan
} else {
    Write-Host "`nRelease ready locally! To trigger the automated GitHub CI/CD build, run:" -ForegroundColor Yellow
    Write-Host "  git push origin main" -ForegroundColor White
    Write-Host "  git push origin $Tag" -ForegroundColor White
    Write-Host "`nGitHub Actions will build universal & split APKs and publish the release." -ForegroundColor Cyan
}
