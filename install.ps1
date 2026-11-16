﻿# ==============================================================================
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
$sourceConfigTemplate = Join-Path $scriptDir "config.template.json"

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

# 2. GEMINI.md 전역 규칙 복사 (상위 ~/.gemini 및 ~/.gemini/config 양쪽 동기화)
if (Test-Path $sourceGeminiMd) {
    $targetGeminiMd1 = Join-Path $targetGeminiDir "GEMINI.md"
    $targetGeminiMd2 = Join-Path $targetConfigDir "GEMINI.md"
    Write-Host "[+] Deploying GEMINI.md -> $targetGeminiMd1 & $targetGeminiMd2" -ForegroundColor Green
    Copy-Item -Path $sourceGeminiMd -Destination $targetGeminiMd1 -Force
    Copy-Item -Path $sourceGeminiMd -Destination $targetGeminiMd2 -Force
} else {
    Write-Host "[!] Warning: GEMINI.md not found in source directory." -ForegroundColor Red
}

# 3. 커스텀 스킬 복사
if (Test-Path $sourceSkillsDir) {
    $skills = Get-ChildItem -Path $sourceSkillsDir -Directory
    Write-Host "[+] Found $($skills.Count) skills to deploy..." -ForegroundColor Green

    foreach ($skill in $skills) {
        $skillDest = Join-Path $targetSkillsDir $skill.Name
        # ego-browser가 이미 ego lite 링크(Junction/Symlink)로 연결되어 있으면 덮어쓰지 않고 유지
        if ($skill.Name -eq "ego-browser" -and (Test-Path -LiteralPath $skillDest)) {
            $destItem = Get-Item -LiteralPath $skillDest -Force
            if ($destItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                if (Test-Path (Join-Path $skillDest "SKILL.md")) {
                    Write-Host "    -> Keeping active ego-browser junction: $skillDest" -ForegroundColor Cyan
                } else {
                    Write-Host "    -> [!] Existing ego-browser junction target is missing (ego lite may need to be launched once): $skillDest" -ForegroundColor Yellow
                }
                continue
            }
        }

        Write-Host "    -> Deploying Skill: $($skill.Name)" -ForegroundColor Gray
        # 부모 디렉터리($targetSkillsDir)를 대상으로 지정해 중첩 복사(<skill>\<skill>) 방지
        Copy-Item -Path $skill.FullName -Destination $targetSkillsDir -Recurse -Force
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
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($hookDest1, $hookProcessed, $utf8NoBom)
    [System.IO.File]::WriteAllText($hookDest2, $hookProcessed, $utf8NoBom)
    Write-Host "    -> Hooks installed to $hookDest1 and $hookDest2" -ForegroundColor Gray
}

# 6. config.template.json 기반 Antigravity userSettings 병합 적용
$targetConfigJson = Join-Path $targetConfigDir "config.json"
if (Test-Path $sourceConfigTemplate) {
    Write-Host "[+] Applying Antigravity userSettings from config.template.json..." -ForegroundColor Green
    try {
        $templateObj = Get-Content $sourceConfigTemplate -Raw -Encoding UTF8 | ConvertFrom-Json
        if (Test-Path $targetConfigJson) {
            $existingObj = Get-Content $targetConfigJson -Raw -Encoding UTF8 | ConvertFrom-Json
        } else {
            $existingObj = [PSCustomObject]@{}
        }

        if (-not ($existingObj.PSObject.Properties.Name -contains "userSettings") -or $null -eq $existingObj.userSettings) {
            $existingObj | Add-Member -NotePropertyName "userSettings" -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        foreach ($prop in $templateObj.userSettings.PSObject.Properties) {
            if ($prop.Name -eq "globalPermissionGrants") {
                if (-not ($existingObj.userSettings.PSObject.Properties.Name -contains "globalPermissionGrants") -or $null -eq $existingObj.userSettings.globalPermissionGrants) {
                    $existingObj.userSettings | Add-Member -NotePropertyName "globalPermissionGrants" -NotePropertyValue ([PSCustomObject]@{ allow = @() }) -Force
                }
                $mergedAllow = @()
                if ($existingObj.userSettings.globalPermissionGrants.allow) {
                    $mergedAllow += $existingObj.userSettings.globalPermissionGrants.allow
                }
                foreach ($grant in $prop.Value.allow) {
                    if ($mergedAllow -notcontains $grant) {
                        $mergedAllow += $grant
                    }
                }
                $existingObj.userSettings.globalPermissionGrants | Add-Member -NotePropertyName "allow" -NotePropertyValue $mergedAllow -Force
            } else {
                $existingObj.userSettings | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
            }
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $jsonOut = $existingObj | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($targetConfigJson, $jsonOut + "`n", $utf8NoBom)
        Write-Host "    -> Merged userSettings into $targetConfigJson" -ForegroundColor Gray
    } catch {
        Write-Host "[!] Warning: Could not merge config.template.json: $_" -ForegroundColor Yellow
    }
}

# 7. Windows User PATH에 scripts 디렉터리 등록 (recycle 명령어 전역 활성화)
try {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathEntries = @()
    if ($userPath) { $pathEntries = $userPath -split ';' | Where-Object { $_ -ne '' } }
    if ($pathEntries -notcontains $targetScriptsDir) {
        Write-Host "[+] Adding scripts directory to User PATH for 'recycle' command..." -ForegroundColor Yellow
        $newUserPath = if ($userPath) { "$($userPath.TrimEnd(';'));$targetScriptsDir" } else { $targetScriptsDir }
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        $env:Path += ";$targetScriptsDir"
        Write-Host "    -> User PATH successfully updated!" -ForegroundColor Green
    } else {
        Write-Host "[+] scripts directory is already in User PATH." -ForegroundColor Gray
    }
} catch {
    Write-Host "[!] Notice: Could not update User PATH automatically: $_" -ForegroundColor Yellow
}

# 8. 설치 검증 및 필수 프로그램(ego-browser, Python, Node.js, Git) 점검
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary & Prerequisite Check" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$installedGeminiMd1 = Test-Path (Join-Path $targetGeminiDir "GEMINI.md")
$installedGeminiMd2 = Test-Path (Join-Path $targetConfigDir "GEMINI.md")
$installedSkillsCount = (Get-ChildItem -Path $targetSkillsDir -Directory -ErrorAction SilentlyContinue).Count
$installedScriptsCount = (Get-ChildItem -Path $targetScriptsDir -File -ErrorAction SilentlyContinue).Count
$installedHook = Test-Path (Join-Path $targetConfigDir "hooks.json")
$installedConfig = Test-Path $targetConfigJson

$hasPython = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
$hasGit = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
$hasNode = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
$hasEgoBrowser = $null -ne (Get-Command ego-browser -ErrorAction SilentlyContinue)

Write-Host "  - GEMINI.md Status  : $(if ($installedGeminiMd1 -and $installedGeminiMd2) { 'Installed [OK]' } else { 'Failed [X]' })" -ForegroundColor $(if ($installedGeminiMd1 -and $installedGeminiMd2) { 'Green' } else { 'Red' })
Write-Host "  - Installed Skills  : $installedSkillsCount skills active" -ForegroundColor Green
Write-Host "  - Installed Scripts : $installedScriptsCount scripts active ($targetScriptsDir)" -ForegroundColor Green
Write-Host "  - Delete Guard Hook : $(if ($installedHook) { 'Active [OK]' } else { 'Not Installed [X]' })" -ForegroundColor $(if ($installedHook) { 'Green' } else { 'Red' })
Write-Host "  - User Settings     : $(if ($installedConfig) { 'Configured [OK]' } else { 'Not Configured [X]' })" -ForegroundColor $(if ($installedConfig) { 'Green' } else { 'Yellow' })
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  - Python 3          : $(if ($hasPython) { 'Ready [OK]' } else { 'MISSING [!] (Required for delete-guard hook & Python skills)' })" -ForegroundColor $(if ($hasPython) { 'Green' } else { 'Red' })
Write-Host "  - Git               : $(if ($hasGit) { 'Ready [OK]' } else { 'MISSING [!]' })" -ForegroundColor $(if ($hasGit) { 'Green' } else { 'Yellow' })
Write-Host "  - Node.js           : $(if ($hasNode) { 'Ready [OK]' } else { 'MISSING [!] (Required for npx MCP tools)' })" -ForegroundColor $(if ($hasNode) { 'Green' } else { 'Yellow' })
Write-Host "  - ego-browser       : $(if ($hasEgoBrowser) { 'Ready [OK]' } else { 'NOT INSTALLED [!] (Action Required)' })" -ForegroundColor $(if ($hasEgoBrowser) { 'Green' } else { 'Yellow' })

if (-not $hasEgoBrowser) {
    Write-Host ""
    Write-Host "[!] ACTION REQUIRED: ego-browser (ego lite) is not installed or not on PATH." -ForegroundColor Yellow
    Write-Host "    1. Download and install ego lite from: https://lite.ego.app/" -ForegroundColor White
    Write-Host "    2. Launch ego lite and complete the first-run onboarding in the GUI." -ForegroundColor White
    Write-Host "    3. Open a NEW terminal and verify:" -ForegroundColor White
    Write-Host "       Get-Command ego-browser" -ForegroundColor Cyan
    Write-Host "       ego-browser nodejs -e `"console.log('ego-browser ready')`"" -ForegroundColor Cyan
    Write-Host "       ego-browser skill" -ForegroundColor Cyan
}

$mcpConfigPath = Join-Path $targetConfigDir "mcp_config.json"
$hasReaMcp = $false
if (Test-Path $mcpConfigPath) {
    $mcpRaw = Get-Content $mcpConfigPath -Raw -Encoding UTF8
    if ($mcpRaw -match '"rea"') { $hasReaMcp = $true }
}
if (-not $hasReaMcp) {
    Write-Host ""
    Write-Host "[i] Optional MCP Setup (reverse-engineer-anything):" -ForegroundColor Gray
    Write-Host "    Run: npx -y rea-agents setup --client antigravity" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Antigravity environment has been configured!" -ForegroundColor Cyan
Write-Host "Please start a new chat session to apply all settings." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
