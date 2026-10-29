# ==============================================================================
# Antigravity Environment One-Click Setup Script (Windows PowerShell)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetConfigDir = Join-Path $HOME ".gemini\config"
$targetSkillsDir = Join-Path $targetConfigDir "skills"
$sourceGeminiMd = Join-Path $scriptDir "GEMINI.md"
$sourceSkillsDir = Join-Path $scriptDir "skills"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting Antigravity Environment Setup..." -ForegroundColor Cyan
Write-Host "  Target Config Directory: $targetConfigDir" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. 대상 디렉터리 확인 및 생성
if (-not (Test-Path $targetSkillsDir)) {
    Write-Host "[+] Creating directory: $targetSkillsDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $targetSkillsDir -Force | Out-Null
}

# 2. GEMINI.md 전역 규칙 복사
if (Test-Path $sourceGeminiMd) {
    $targetGeminiMd = Join-Path $targetConfigDir "GEMINI.md"
    Write-Host "[+] Copying GEMINI.md -> $targetGeminiMd" -ForegroundColor Green
    Copy-Item -Path $sourceGeminiMd -Destination $targetGeminiMd -Force
} else {
    Write-Host "[!] Warning: GEMINI.md not found in source directory." -ForegroundColor Red
}

# 3. 커스텀 스킬 복사
if (Test-Path $sourceSkillsDir) {
    $skills = Get-ChildItem -Path $sourceSkillsDir -Directory
    Write-Host "[+] Found $($skills.Count) skills to deploy..." -ForegroundColor Green
    
    foreach ($skill in $skills) {
        $skillDest = Join-Path $targetSkillsDir $skill.Name
        Write-Host "    -> Deploying: $($skill.Name)" -ForegroundColor Gray
        Copy-Item -Path $skill.FullName -Destination $skillDest -Recurse -Force
    }
} else {
    Write-Host "[!] Warning: skills directory not found in source directory." -ForegroundColor Red
}

# 4. 검증 및 결과 보고
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary & Verification" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$installedGeminiMd = Test-Path (Join-Path $targetConfigDir "GEMINI.md")
$installedSkillsCount = (Get-ChildItem -Path $targetSkillsDir -Directory -ErrorAction SilentlyContinue).Count

Write-Host "  - GEMINI.md Status : $(if ($installedGeminiMd) { 'Installed [OK]' } else { 'Failed [X]' })" -ForegroundColor $(if ($installedGeminiMd) { 'Green' } else { 'Red' })
Write-Host "  - Installed Skills : $installedSkillsCount skills active" -ForegroundColor Green
Write-Host ""
Write-Host "Antigravity environment has been successfully configured!" -ForegroundColor Cyan
Write-Host "Please start a new chat session to apply all settings." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
