# ==============================================================================
# Antigravity Environment One-Click Setup Script (Windows PowerShell)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetGeminiDir = Join-Path $HOME ".gemini"
$targetConfigDir = Join-Path $targetGeminiDir "config"
$targetSkillsDir = Join-Path $targetConfigDir "skills"
$targetScriptsDir = Join-Path $targetGeminiDir "scripts"

$sourceGeminiMd = Join-Path $scriptDir "GEMINI.md"
$sourceSkillsDir = Join-Path $scriptDir "skills"
$sourceScriptsDir = Join-Path $scriptDir "scripts"
$sourceHooksJson = Join-Path $scriptDir "hooks.json"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Starting Antigravity Environment Setup..." -ForegroundColor Cyan
Write-Host "  Target Gemini Directory: $targetGeminiDir" -ForegroundColor Gray
Write-Host "  Target Config Directory: $targetConfigDir" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. 대상 디렉터리 확인 및 생성
$dirsToCreate = @($targetConfigDir, $targetSkillsDir, $targetScriptsDir)
foreach ($dir in $dirsToCreate) {
    if (-not (Test-Path $dir)) {
        Write-Host "[+] Creating directory: $dir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 2. GEMINI.md 전역 규칙 복사 (상위 ~/.gemini 및 ~/.gemini/config 양쪽 지원)
if (Test-Path $sourceGeminiMd) {
    $targetGeminiMd1 = Join-Path $targetGeminiDir "GEMINI.md"
    $targetGeminiMd2 = Join-Path $targetConfigDir "GEMINI.md"
    Write-Host "[+] Deploying GEMINI.md -> $targetGeminiMd2" -ForegroundColor Green
    Copy-Item -Path $sourceGeminiMd -Destination $targetGeminiMd2 -Force
    Copy-Item -Path $sourceGeminiMd -Destination $targetGeminiMd1 -Force
} else {
    Write-Host "[!] Warning: GEMINI.md not found in source directory." -ForegroundColor Red
}

# 3. 커스텀 스킬 복사
if (Test-Path $sourceSkillsDir) {
    $skills = Get-ChildItem -Path $sourceSkillsDir -Directory
    Write-Host "[+] Found $($skills.Count) skills to deploy..." -ForegroundColor Green
    
    foreach ($skill in $skills) {
        $skillDest = Join-Path $targetSkillsDir $skill.Name
        Write-Host "    -> Deploying Skill: $($skill.Name)" -ForegroundColor Gray
        Copy-Item -Path $skill.FullName -Destination $skillDest -Recurse -Force
    }
} else {
    Write-Host "[!] Warning: skills directory not found in source directory." -ForegroundColor Red
}

# 4. 안전 스크립트 복사 (~/.gemini/scripts)
if (Test-Path $sourceScriptsDir) {
    $scripts = Get-ChildItem -Path $sourceScriptsDir -File
    Write-Host "[+] Found $($scripts.Count) scripts to deploy..." -ForegroundColor Green
    
    foreach ($s in $scripts) {
        $scriptDest = Join-Path $targetScriptsDir $s.Name
        Write-Host "    -> Deploying Script: $($s.Name)" -ForegroundColor Gray
        Copy-Item -Path $s.FullName -Destination $scriptDest -Force
    }
} else {
    Write-Host "[!] Warning: scripts directory not found in source directory." -ForegroundColor Red
}

# 5. hooks.json 복사 및 동적 경로 적용 (영구 삭제 차단 가드 훅)
if (Test-Path $sourceHooksJson) {
    Write-Host "[+] Configuring delete-guard hook (hooks.json)..." -ForegroundColor Green
    $hookTemplate = Get-Content $sourceHooksJson -Raw -Encoding UTF8
    $escapedScriptsDir = $targetScriptsDir -replace '\\', '\\\\'
    $hookProcessed = $hookTemplate.Replace("{{SCRIPTS_DIR}}", $escapedScriptsDir)
    
    $hookDest1 = Join-Path $targetGeminiDir "hooks.json"
    $hookDest2 = Join-Path $targetConfigDir "hooks.json"
    Set-Content -Path $hookDest1 -Value $hookProcessed -Encoding UTF8
    Set-Content -Path $hookDest2 -Value $hookProcessed -Encoding UTF8
    Write-Host "    -> Hooks installed to $hookDest1 and $hookDest2" -ForegroundColor Gray
}

# 6. Windows User PATH에 scripts 디렉터리 등록 (recycle 명령어 전역 활성화)
try {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$targetScriptsDir*") {
        Write-Host "[+] Adding scripts directory to User PATH for 'recycle' command..." -ForegroundColor Yellow
        $newUserPath = if ($userPath) { "$userPath;$targetScriptsDir" } else { $targetScriptsDir }
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        $env:Path += ";$targetScriptsDir"
        Write-Host "    -> User PATH successfully updated!" -ForegroundColor Green
    } else {
        Write-Host "[+] scripts directory is already in User PATH." -ForegroundColor Gray
    }
} catch {
    Write-Host "[!] Notice: Could not update User PATH automatically: $_" -ForegroundColor Yellow
}

# 7. 검증 및 결과 보고
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary & Verification" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$installedGeminiMd = Test-Path (Join-Path $targetConfigDir "GEMINI.md")
$installedSkillsCount = (Get-ChildItem -Path $targetSkillsDir -Directory -ErrorAction SilentlyContinue).Count
$installedScriptsCount = (Get-ChildItem -Path $targetScriptsDir -File -ErrorAction SilentlyContinue).Count
$installedHook = Test-Path (Join-Path $targetConfigDir "hooks.json")

Write-Host "  - GEMINI.md Status  : $(if ($installedGeminiMd) { 'Installed [OK]' } else { 'Failed [X]' })" -ForegroundColor $(if ($installedGeminiMd) { 'Green' } else { 'Red' })
Write-Host "  - Installed Skills  : $installedSkillsCount skills active" -ForegroundColor Green
Write-Host "  - Installed Scripts : $installedScriptsCount scripts active ($targetScriptsDir)" -ForegroundColor Green
Write-Host "  - Delete Guard Hook : $(if ($installedHook) { 'Active [OK]' } else { 'Not Installed [X]' })" -ForegroundColor Green
Write-Host ""
Write-Host "Antigravity environment has been successfully configured!" -ForegroundColor Cyan
Write-Host "Please start a new chat session to apply all settings." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
