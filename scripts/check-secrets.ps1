[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$paths = @(
  (git diff --cached --name-only)
  (git diff --name-only)
  (git ls-files --others --exclude-standard)
) | Where-Object { $_ } | Sort-Object -Unique

$blockedPathPattern = '(^|/)(\.env(?:\.[^/]+)?|.*\.(pem|key|p12|jks|keystore))$'
$blockedContentPattern = 'BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|R2_SECRET_ACCESS_KEY\s*=\s*(?!replace-with-)'
$violations = @()

foreach ($path in $paths) {
  $normalizedPath = $path.Replace('\\', '/')
  if ($normalizedPath -match $blockedPathPattern -and $normalizedPath -notmatch '(^|/)\.env\.example$') {
    $violations += "credential-like path: $normalizedPath"
    continue
  }

  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match $blockedContentPattern) {
      $violations += "credential-like content: $normalizedPath"
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Error ("Secret scan failed:`n" + ($violations -join "`n"))
  exit 1
}

Write-Output 'Secret scan passed.'
