<#
Push changelog script.
Usage:
  From repo root:
    .\scripts\push_changelog.ps1 -RepoUrl "https://github.com/moisboy4/ark" -WebhookUrl "https://discord.com/api/webhooks/.." -Message "Your change summary"
  If you omit -Message you'll be prompted to type it.
Notes:
  - This script expects `git` to be available and authentication to be configured (SSH key or credential helper/PAT).
  - It will append an entry to `CHANGELOG.md`, commit it, push to the current branch on the provided remote, and notify the provided Discord webhook.
#>
param(
    [string]$RepoUrl = 'https://github.com/moisboy4/ark',
    [string]$WebhookUrl = 'https://discord.com/api/webhooks/1460583008640827394/AUDDdlPrg9VcLDS6QWqXOx7nP-kSPXviPoX2Ta_ooSoVedo1cuHXpIZZMH5ZlexWGA-P',
    [string]$Message
)
function ExitOnError($code,$msg){ if($code -ne 0){ Write-Host $msg; exit $code } }
if(-not (Get-Command git -ErrorAction SilentlyContinue)){ Write-Host 'git not found on PATH. Install git and ensure it is accessible.'; exit 1 }
if(-not $Message){ $Message = Read-Host 'Enter changelog message' }
$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$entry = "### $now`n$Message`n`n"
$changelog = Join-Path (Get-Location) 'CHANGELOG.md'
if(-not (Test-Path $changelog)) { New-Item -ItemType File -Path $changelog -Force | Out-Null }
Add-Content -Path $changelog -Value $entry
# Ensure remote exists or add temporary remote
$remoteName = 'ark_remote'
$existing = git remote | Where-Object { $_ -eq $remoteName }
if(-not $existing){
    git remote add $remoteName $RepoUrl
    if($LASTEXITCODE -ne 0){ Write-Host 'Failed to add remote. Ensure URL is valid and you have permission.'; exit $LASTEXITCODE }
}
# Stage and commit
git add CHANGELOG.md
if($LASTEXITCODE -ne 0){ Write-Host 'git add failed'; exit $LASTEXITCODE }
$branch = git rev-parse --abbrev-ref HEAD
if($LASTEXITCODE -ne 0){ Write-Host 'Failed to get current branch'; exit $LASTEXITCODE }
$commitMsg = "chore(changelog): $Message"
git commit -m "$commitMsg"
if($LASTEXITCODE -ne 0){ Write-Host 'Nothing to commit or commit failed.' }
# Push
git push $remoteName $branch
if($LASTEXITCODE -ne 0){ Write-Host 'git push failed. Ensure authentication (PAT/SSH) is configured.'; exit $LASTEXITCODE }
# Send Discord webhook notification
$payload = @{ content = "New changelog pushed to $RepoUrl on branch $branch`nMessage: $Message" }
try{
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body (ConvertTo-Json $payload) -ContentType 'application/json'
    Write-Host 'Discord webhook sent.'
} catch { Write-Warning "Failed to send webhook: $_" }
Write-Host 'Done.'
