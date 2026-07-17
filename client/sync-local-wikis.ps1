<#
.SYNOPSIS
    Client-side script for Windows to automatically discover, clone, or update
    all Markdown/Wiki repositories from a Gitea Organization.
.DESCRIPTION
    This script queries the Gitea API, filters the repositories, and enforces
    Obsidian protection guidelines in the .gitignore file locally.
.PARAMETER Token
    The Gitea Personal Access Token passed as the first argument.
#>

# --- Configuration & Environment Variables ---
$GiteaUrl = "https://gitea.yourdomain.com"
$OrgName  = "your-organization"
$DestDir  = Join-Path $HOME "Obsidian-Vaults"
$Token    = $args[0]

# --- Validation ---
if ([string]::IsNullOrEmpty($Token)) {
    Write-Host "[-] Error: Missing Gitea Access Token." -ForegroundColor Red
    Write-Host "Usage: .\sync-local-wikis.ps1 <YOUR_GITEA_TOKEN>" -ForegroundColor Yellow
    Exit 1
}

# --- Step 1: Initialize Workspace Directory ---
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}
Set-Location $DestDir

Write-Host "[+] Fetching repository list from organization: $OrgName..." -ForegroundColor Green

# --- Step 2: Query Gitea API for Repositories ---
# RestSharp/HttpClient wrapper inside PowerShell handles JSON objects dynamically
$ApiUrl = "$GiteaUrl/api/v1/orgs/$OrgName/repos?access_token=$Token&limit=100"

try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Get -ErrorAction Stop
    $Repos = $Response.name
} catch {
    Write-Host "[-] Error: Unable to fetch repository list. Check your URL, Token, or Organization name." -ForegroundColor Red
    Exit 1
}

if ($null -eq $Repos -or $Repos.Count -eq 0) {
    Write-Host "[-] No repositories found or token lacks authorized scope." -ForegroundColor Red
    Exit 1
}

# --- Step 3: Iterate and Sync Each Repository ---
foreach ($RepoName in $Repos) {

    # EXCLUSION FILTERS: Define repositories that should NOT be synced into the local vault
    if ($RepoName -eq "main-portal" -or $RepoName -eq "base-template" -or $RepoName -like "IGNORE-*") {
        Write-Host "[!] Skipping filtered repository: $RepoName" -ForegroundColor Yellow
        continue
    }

    # Extract raw domain host from Gitea URL for authenticated clone formatting
    $DomainHost = $GiteaUrl -replace '^[^/]*//', ''
    $AuthCloneUrl = "https://$Token@$DomainHost/$OrgName/$RepoName.git"

    # --- Step 4: Clone New or Pull Existing Repositories ---
    $RepoPath = Join-Path $DestDir $RepoName

    if (Test-Path $RepoPath) {
        Write-Host "[+] Updating existing local wiki: $RepoName..." -ForegroundColor Yellow
        Set-Location $RepoPath
        
        # Discard local uncommitted drift conflicts using native git commands
        git pull --force
    } else {
        Write-Host "[+] Cloning new wiki configuration: $RepoName..." -ForegroundColor Cyan
        git clone $AuthCloneUrl
        Set-Location $RepoPath
    }

    # --- Step 4.1: Enforce Obsidian Rules safely if .gitignore doesn't have them ---
    $GitignorePath = Join-Path $RepoPath ".gitignore"
    $NeedsInjection = $true

    if (Test-Path $GitignorePath) {
        $Content = Get-Content $GitignorePath -Raw
        if ($Content -match "\.obsidian/workspace\.json") {
            $NeedsInjection = $false
        }
    }

    if ($NeedsInjection) {
        Write-Host "[+] Injecting missing Obsidian protection rules into .gitignore..."
        $Rules = @"

# Added automatically by sync script to prevent vault locking conflicts
.obsidian/workspace.json
.obsidian/workspace
.obsidian/graph.json
.obsidian/plugins/obsidian-git/queue.json
"@
        Add-Content -Path $GitignorePath -Value $Rules
    }

    # Step out back to the root directory before the next iteration
    Set-Location $DestDir
}

# --- Step 5: Finalization Notification ---
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Green
Write-Host " Success! All authorized organization wikis are ready at:" -ForegroundColor Green
Write-Host " -> $DestDir" -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Green
