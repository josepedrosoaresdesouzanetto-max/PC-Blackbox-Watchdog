[CmdletBinding()]
param(
    [string]$RepoName = "PC-Blackbox-Watchdog",
    [switch]$Public
)

$ErrorActionPreference = "Stop"
$repoVisibility = if ($Public) { "--public" } else { "--private" }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI não encontrado. Instale com: winget install --id GitHub.cli"
}

$auth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Você precisa entrar no GitHub primeiro:"
    Write-Host "gh auth login"
    throw "GitHub CLI não autenticado."
}

if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    git add .
    git commit -m "Release PC-Blackbox-Watchdog v1.0.2"
}

gh repo create $RepoName $repoVisibility --source . --remote origin --push
Write-Host "Repositório criado e enviado para o GitHub: $RepoName"
