# Installs project/ into the current directory: copies every file that does not exist yet, never overwrites one.
# -Update also overwrites the framework files listed in .claude/sdd-core — your files (project.md, gates.conf, settings.json, specs/, docs/) stay untouched.
# Usage: irm https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.ps1 | iex
#        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/stevenhdz/spec-driven-development/main/install.ps1))) [-Update] [-Ref <tag|branch>]
# Exit: returns without installing when the download fails — no exit, so the PowerShell window stays open
param([string]$Ref = 'main', [switch]$Update)

$repo = 'stevenhdz/spec-driven-development'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null

function Test-Core([string]$f, [string[]]$core) {
  foreach ($p in $core) {
    if ($p.EndsWith('/')) { if ($f.StartsWith($p)) { return $true } }
    elseif ($f -eq $p) { return $true }
  }
  return $false
}

function Test-Same([string]$a, [string]$b) {
  (Get-FileHash -LiteralPath $a).Hash -eq (Get-FileHash -LiteralPath $b).Hash
}

try {
  try {
    Invoke-WebRequest "https://codeload.github.com/$repo/zip/$Ref" -OutFile "$tmp/sdd.zip" -UseBasicParsing -ErrorAction Stop
    Expand-Archive "$tmp/sdd.zip" -DestinationPath $tmp -ErrorAction Stop
  } catch {
    Write-Host "SDD: ❌ could not download $repo@$Ref"
    return
  }
  $src = Join-Path (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName 'project'
  $coreFile = Join-Path $src '.claude/sdd-core'
  $core = @()
  if (Test-Path -LiteralPath $coreFile) { $core = @(Get-Content $coreFile | Where-Object { $_ -and -not $_.StartsWith('#') }) }

  $legacy = $Update -and (Test-Path -LiteralPath 'CLAUDE.md') -and -not (Test-Path -LiteralPath '.claude/project.md') -and
    -not (Get-Content 'CLAUDE.md' | Where-Object { $_ -eq '@.claude/project.md' })
  $overwrite = $Update -and -not $legacy

  $added = 0
  $updated = 0
  $kept = @()
  foreach ($file in Get-ChildItem $src -Recurse -File -Force) {
    $f = $file.FullName.Substring($src.Length + 1) -replace '\\', '/'
    if (Test-Path -LiteralPath $f) {
      if (Test-Same $file.FullName $f) { continue }
      if ($overwrite -and (Test-Core $f $core)) {
        Copy-Item -LiteralPath $file.FullName -Destination $f -Force
        $updated++
      } else {
        $kept += $f
      }
      continue
    }
    $dir = Split-Path $f -Parent
    if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item -LiteralPath $file.FullName -Destination $f
    $added++
  }

  Write-Host "SDD ${Ref}: ✅ $added files added · $updated updated"
  if ($kept.Count -gt 0) {
    Write-Host "Kept yours, differs from ${Ref}:"
    foreach ($f in $kept) { Write-Host "  $f" }
    Write-Host "Compare with ${Ref}: https://github.com/$repo/tree/$Ref/project"
  }
  if ($legacy) {
    Write-Host 'CLAUDE.md predates v1.6: nothing updated — move your values into .claude/project.md, then rerun with -Update'
  }
  if ($Update) {
    Write-Host 'Next: review git diff'
  } else {
    Write-Host 'Next: existing code → open Claude Code and run /adopt · new project → fill the [placeholders] (readme → Setup)'
  }
} finally {
  Remove-Item -Recurse -Force $tmp
}
