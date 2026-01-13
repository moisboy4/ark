<#
Safe repo-wide rename script.
Usage:
  - Run from repo root: .\scripts\rename_ARKANE_to_arkane.ps1
  - Or: powershell -ExecutionPolicy Bypass -File .\scripts\rename_ARKANE_to_arkane.ps1 -Path .
This script will:
  - Search text files for occurrences of "ARKANE" (case-insensitive) and replace them with "arkane" preserving simple casing variants.
  - Rename files and directories whose names contain "ARKANE" (case-insensitive) to use "arkane".
  - Create a backup copy of changed files under .git/rename_backup_TIMESTAMP (if .git exists), otherwise prompt.
Note: Review changes and commit them yourself (or use the provided push script).
#>
param(
    [string]$Path = ".",
    [switch]$WhatIf
)
function Confirm-OrExit($msg){
    $r = Read-Host "$msg  [Y/N]"
    if($r -notin @('Y','y')){ Write-Host 'Aborting.'; exit 1 }
}
Write-Host "Running rename in path: $Path"
if(-not (Test-Path $Path)) { Write-Host "Path does not exist: $Path"; exit 1 }
$gitDir = Join-Path $Path '.git'
$backupRoot = $null
if(Test-Path $gitDir){
    $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
    $backupRoot = Join-Path $gitDir "rename_backup_$ts"
    if(-not $WhatIf){ New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
    Write-Host "Backups will be placed under: $backupRoot"
} else {
    Write-Host "No .git found; changes will be applied directly. If you want a backup, create one or run inside a clone." 
}
# file extensions to treat as text
$extRegex = '^(\.c(pp)?|\.h(pp)?|\.hpp|\.c|\.h|\.txt|\.md|\.sln|\.vcxproj|\.xml|\.json|\.rc|\.ini|\.cfg|\.cpp|\.cs|\.py|\.ps1|\.txt|\.log)$'
$files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match $extRegex -or $_.Extension -eq '' }
$changedFiles = @()
foreach($f in $files){
    try{
        $text = Get-Content -Raw -ErrorAction Stop -LiteralPath $f.FullName
    } catch { continue }
    $new = $text -replace '(?i)ARKANE','ARKANE' -replace '(?i)ARKANE','Arkane' -replace '(?i)ARKANE','arkane'
    if($new -ne $text){
        if($backupRoot){
            $rel = Resolve-Path -LiteralPath $f.FullName -Relative -ErrorAction SilentlyContinue
            $dest = Join-Path $backupRoot ($f.FullName.Replace(':','').Replace('\','_'))
            Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
        }
        if($WhatIf){ Write-Host "[WhatIf] Would update: $($f.FullName)"; continue }
        Set-Content -LiteralPath $f.FullName -Value $new -Force
        $changedFiles += $f.FullName
        Write-Host "Updated: $($f.FullName)"
    }
}
# Rename files and directories containing 'ARKANE' (case-insensitive)
# Do directories deepest-first
$items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)ARKANE' } | Sort-Object { $_.FullName.Length } -Descending
foreach($it in $items){
    $newName = $it.Name -replace '(?i)ARKANE','ARKANE' -replace '(?i)ARKANE','Arkane' -replace '(?i)ARKANE','arkane'
    $parent = Split-Path -LiteralPath $it.FullName -Parent
    $newFull = Join-Path $parent $newName
    if($WhatIf){ Write-Host "[WhatIf] Would rename: $($it.FullName) -> $newFull"; continue }
    try{
        Rename-Item -LiteralPath $it.FullName -NewName $newName -Force
        Write-Host "Renamed: $($it.FullName) -> $newFull"
    } catch { Write-Warning "Failed to rename $($it.FullName): $_" }
}
Write-Host "Rename operation completed. Files changed: $($changedFiles.Count)"
if($changedFiles.Count -gt 0){ Write-Host 'Please review changes, stage and commit them.' }
Write-Host 'Done.'

