# Installs project/ into the current directory: copies every file that does not exist yet, never overwrites one.
# Usage: irm https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.ps1 | iex
#        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.ps1))) -Ref <tag|branch>
# Exit: returns without installing when the download fails — no exit, so the PowerShell window stays open
param([string]$Ref = 'main')

$repo = 'stevenhdz/spec-driven-development'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
  try {
    Invoke-WebRequest "https://codeload.github.com/$repo/zip/$Ref" -OutFile "$tmp/sdd.zip" -UseBasicParsing -ErrorAction Stop
    Expand-Archive "$tmp/sdd.zip" -DestinationPath $tmp -ErrorAction Stop
  } catch {
    Write-Host "SDD: ❌ could not download $repo@$Ref"
    return
  }
  $src = Join-Path (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName 'project'

  $added = 0
  $kept = @()
  foreach ($file in Get-ChildItem $src -Recurse -File -Force) {
    $f = $file.FullName.Substring($src.Length + 1) -replace '\\', '/'
    if (Test-Path -LiteralPath $f) {
      $kept += $f
      continue
    }
    $dir = Split-Path $f -Parent
    if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item -LiteralPath $file.FullName -Destination $f
    $added++
  }

  Write-Host "SDD ${Ref}: ✅ $added files added"
  if ($kept.Count -gt 0) {
    Write-Host 'Kept existing, not overwritten:'
    foreach ($f in $kept) { Write-Host "  $f" }
    Write-Host "Merge them by hand with ${Ref}: https://github.com/$repo/tree/$Ref/project"
  }
  Write-Host 'Next: existing code → open Claude Code and run /adopt · new project → fill the [placeholders] (readme → Setup)'
} finally {
  Remove-Item -Recurse -Force $tmp
}
