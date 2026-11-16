﻿# ==============================================================================
# Antigravity Dotfiles Auto Sync & Push Script
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceGeminiDir = Join-Path $HOME ".gemini"
$sourceConfigDir = Join-Path $sourceGeminiDir "config"
$sourceSkillsDir = Join-Path $sourceConfigDir "skills"
$sourceScriptsDir = Join-Path $sourceGeminiDir "scripts"
$sourceConfigJson = Join-Path $sourceConfigDir "config.json"

$repoSkillsDir = Join-Path $scriptDir "skills"
$repoScriptsDir = Join-Path $scriptDir "scripts"
$repoGeminiMd = Join-Path $scriptDir "GEMINI.md"
$repoConfigTemplate = Join-Path $scriptDir "config.template.json"

# 저장소에서 의도적으로 제외하는 로컬 전용 스킬 목록
$excludedSkills = @('culinary-master')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Normalize-HomePaths {
    param([string]$Text)
    $escapedHome = [regex]::Escape($HOME)
    $res = $Text -replace $escapedHome, '$HOME'
    $res = $res -replace 'C:\\Users\\[^\\/\s"''`]+', '$HOME'
    return $res
}

function Resolve-EgoBrowserSkillSource {
    param([string]$LocalSkillPath)
    if ((Test-Path $LocalSkillPath) -and (Get-ChildItem -Path $LocalSkillPath -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        return $LocalSkillPath
    }
    $egoShare = Join-Path $HOME ".local\share\ego\ego-skills"
    if ((Test-Path $egoShare) -and (Test-Path (Join-Path $egoShare "SKILL.md"))) {
        return $egoShare
    }
    $appRoot = "C:\Program Files\Citro Labs\ego lite\Application"
    if (Test-Path $appRoot) {
        $latest = Get-ChildItem -Path $appRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName "ego-skills\ego-browser\SKILL.md") } |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($latest) {
            return (Join-Path $latest.FullName "ego-skills\ego-browser")
        }
    }
    return $null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Antigravity Dotfiles Auto Sync & Push" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Source : $sourceGeminiDir" -ForegroundColor Gray
Write-Host "  Repo   : $scriptDir" -ForegroundColor Gray
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

# 1. 원격 저장소 최신 상태 확인 및 pull --rebase
Write-Host "[1/5] 원격 저장소 최신 변경사항 확인 중..." -ForegroundColor Yellow
git -C $scriptDir fetch origin 2>$null
$behind = git -C $scriptDir rev-list HEAD..origin/main --count 2>$null
if ($behind -and [int]$behind -gt 0) {
    Write-Host "    -> 원격에 $behind 개의 신규 커밋이 있습니다. Pull(rebase) 진행..." -ForegroundColor Magenta
    git -C $scriptDir pull --rebase origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [!] 오류: git pull --rebase 실패. 충돌을 먼저 해결한 뒤 다시 실행하세요." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "    -> 원격 저장소와 최신 상태가 일치합니다." -ForegroundColor Green
}

# 2. GEMINI.md 동기화 (개인 계정 경로 일반화)
Write-Host "[2/5] GEMINI.md 전역 규칙 동기화 중..." -ForegroundColor Yellow
$sourceGeminiMd1 = Join-Path $sourceGeminiDir "GEMINI.md"
$sourceGeminiMd2 = Join-Path $sourceConfigDir "GEMINI.md"
$sourceGeminiMd = if (Test-Path $sourceGeminiMd2) { $sourceGeminiMd2 } else { $sourceGeminiMd1 }

if ((Test-Path $sourceGeminiMd1) -and (Test-Path $sourceGeminiMd2)) {
    if ((Get-FileHash $sourceGeminiMd1).Hash -ne (Get-FileHash $sourceGeminiMd2).Hash) {
        Write-Host "    [!] 안내: ~/.gemini/GEMINI.md 와 ~/.gemini/config/GEMINI.md 내용이 다릅니다. config/GEMINI.md 기준으로 동기화합니다." -ForegroundColor Yellow
    }
}

if (Test-Path $sourceGeminiMd) {
    $geminiContent = Get-Content -Path $sourceGeminiMd -Raw -Encoding UTF8
    $normalizedContent = Normalize-HomePaths $geminiContent
    [System.IO.File]::WriteAllText($repoGeminiMd, $normalizedContent, $utf8NoBom)
    Write-Host "    -> GEMINI.md 동기화 및 경로 정규화 완료." -ForegroundColor Green
} else {
    Write-Host "    [!] 경고: 로컬 GEMINI.md 파일을 찾을 수 없습니다." -ForegroundColor Red
}

# 3. 커스텀 스킬 동기화 (skills/)
Write-Host "[3/5] 커스텀 스킬 동기화 중..." -ForegroundColor Yellow
if (Test-Path $sourceSkillsDir) {
    if (-not (Test-Path $repoSkillsDir)) {
        New-Item -ItemType Directory -Path $repoSkillsDir -Force | Out-Null
    }

    $skills = Get-ChildItem -Path $sourceSkillsDir -Directory
    $syncedSkillsCount = 0

    foreach ($skill in $skills) {
        if ($excludedSkills -contains $skill.Name) {
            Write-Host "    -> 제외된 스킬 건너뜀: $($skill.Name)" -ForegroundColor DarkGray
            continue
        }

        $skillSourcePath = $skill.FullName
        if ($skill.Name -eq "ego-browser") {
            $resolvedEgo = Resolve-EgoBrowserSkillSource $skillSourcePath
            if (-not $resolvedEgo) {
                Write-Host "    [!] 경고: ego-browser 스킬 소스를 찾을 수 없어 건너뜁니다." -ForegroundColor Yellow
                continue
            }
            $skillSourcePath = $resolvedEgo
        }

        $skillDest = Join-Path $repoSkillsDir $skill.Name
        if (-not (Test-Path $skillDest)) {
            New-Item -ItemType Directory -Path $skillDest -Force | Out-Null
        }

        $files = Get-ChildItem -Path $skillSourcePath -Recurse -File | Where-Object {
            $_.Extension -ne '.bak' -and
            $_.Extension -ne '.pyc' -and
            $_.FullName -notmatch '__pycache__'
        }
        foreach ($file in $files) {
            $relPath = $file.FullName.Substring($skillSourcePath.Length).TrimStart('\', '/')
            $destFilePath = Join-Path $skillDest $relPath
            $destFileDir = Split-Path -Parent $destFilePath
            if (-not (Test-Path $destFileDir)) {
                New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null
            }

            if ($file.Extension -eq '.md') {
                $rawMd = Get-Content -Path $file.FullName -Raw -Encoding UTF8
                $normMd = Normalize-HomePaths $rawMd
                $existingMd = if (Test-Path $destFilePath) { Get-Content -Path $destFilePath -Raw -Encoding UTF8 } else { $null }
                if ($normMd -ne $existingMd) {
                    [System.IO.File]::WriteAllText($destFilePath, $normMd, $utf8NoBom)
                }
            } else {
                $needCopy = $true
                if (Test-Path $destFilePath) {
                    if ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $destFilePath).Hash) {
                        $needCopy = $false
                    }
                }
                if ($needCopy) {
                    Copy-Item -Path $file.FullName -Destination $destFilePath -Force
                }
            }
        }
        $syncedSkillsCount++
    }
    Write-Host "    -> $syncedSkillsCount 개 스킬 동기화 완료." -ForegroundColor Green
} else {
    Write-Host "    [!] 경고: 스킬 디렉터리를 찾을 수 없습니다: $sourceSkillsDir" -ForegroundColor Red
}

# 4. 안전 스크립트 동기화 (scripts/)
Write-Host "[4/5] 안전 삭제 스크립트 동기화 중..." -ForegroundColor Yellow
if (Test-Path $sourceScriptsDir) {
    if (-not (Test-Path $repoScriptsDir)) {
        New-Item -ItemType Directory -Path $repoScriptsDir -Force | Out-Null
    }

    $targetScripts = @('recycle.ps1', 'recycle.cmd', 'check_delete_guard.py')
    foreach ($sName in $targetScripts) {
        $sSource = Join-Path $sourceScriptsDir $sName
        $sDest = Join-Path $repoScriptsDir $sName
        if (Test-Path $sSource) {
            if ($sName -eq 'check_delete_guard.py') {
                $pyContent = Get-Content -Path $sSource -Raw -Encoding UTF8
                $normalizedPy = Normalize-HomePaths $pyContent
                [System.IO.File]::WriteAllText($sDest, $normalizedPy, $utf8NoBom)
            } else {
                Copy-Item -Path $sSource -Destination $sDest -Force
            }
            Write-Host "    -> 스크립트 동기화: $sName" -ForegroundColor Gray
        }
    }
    Write-Host "    -> 안전 스크립트 동기화 완료." -ForegroundColor Green
}

# 5. Antigravity userSettings 템플릿 동기화 (config.template.json)
Write-Host "[5/5] 전역 설정 템플릿(config.template.json) 동기화 중..." -ForegroundColor Yellow
if (Test-Path $sourceConfigJson) {
    try {
        $cfgObj = Get-Content -Path $sourceConfigJson -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfgObj.userSettings) {
            $filteredSettings = [ordered]@{}
            foreach ($prop in $cfgObj.userSettings.PSObject.Properties) {
                if ($prop.Name -notin @('remoteControlEnabled', 'remoteControlHostname')) {
                    $filteredSettings[$prop.Name] = $prop.Value
                }
            }
            $templateObj = [ordered]@{ userSettings = $filteredSettings }
            $jsonStr = ($templateObj | ConvertTo-Json -Depth 10) + "`n"
            [System.IO.File]::WriteAllText($repoConfigTemplate, $jsonStr, $utf8NoBom)
            Write-Host "    -> config.template.json 동기화 완료 (민감/기기별 항목 제외)." -ForegroundColor Green
        }
    } catch {
        Write-Host "    [!] 경고: config.json 파싱 실패: $_" -ForegroundColor Yellow
    }
}

# 6. Git 변경 감지 및 자동 커밋 / 푸시
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Git 변경 사항 점검 중..." -ForegroundColor Cyan

$status = git -C $scriptDir status --porcelain
if ($status) {
    Write-Host "변경된 파일 감지됨:" -ForegroundColor Magenta
    git -C $scriptDir status -s

    Write-Host ""
    Write-Host "[+] 변경 파일 스테이징 중 (git add .)..." -ForegroundColor Yellow
    git -C $scriptDir add .

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMsg = "auto: sync global config and skills ($timestamp)"
    Write-Host "[+] 커밋 생성 중: '$commitMsg'..." -ForegroundColor Yellow
    git -C $scriptDir commit -m $commitMsg

    Write-Host "[+] 원격 저장소 푸시 중 (git push origin main)..." -ForegroundColor Yellow
    $pushResult = git -C $scriptDir push origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host "  [성공] 모든 변경사항이 GitHub에 정상 푸시되었습니다!" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Red
        Write-Host "  [오류] Git push 중 문제가 발생했습니다:" -ForegroundColor Red
        Write-Host $pushResult -ForegroundColor Red
        Write-Host "==========================================================" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  [최신 상태] 로컬 전역 설정과 저장소 내용이 이미 동일합니다." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
}
