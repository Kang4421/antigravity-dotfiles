# ==============================================================================
# Antigravity Dotfiles Auto Sync & Push Script
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceGeminiDir = Join-Path $HOME ".gemini"
$sourceConfigDir = Join-Path $sourceGeminiDir "config"
$sourceSkillsDir = Join-Path $sourceConfigDir "skills"
$sourceScriptsDir = Join-Path $sourceGeminiDir "scripts"

$repoSkillsDir = Join-Path $scriptDir "skills"
$repoScriptsDir = Join-Path $scriptDir "scripts"
$repoGeminiMd = Join-Path $scriptDir "GEMINI.md"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Antigravity Dotfiles Auto Sync & Push" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Source : $sourceGeminiDir" -ForegroundColor Gray
Write-Host "  Repo   : $scriptDir" -ForegroundColor Gray
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

# 1. 원격 저장소 최신 상태 확인 및 pull --rebase
Write-Host "[1/4] 원격 저장소 최신 변경사항 확인 중..." -ForegroundColor Yellow
try {
    git -C $scriptDir fetch origin 2>$null
    $behind = git -C $scriptDir rev-list HEAD..origin/main --count 2>$null
    if ($behind -and [int]$behind -gt 0) {
        Write-Host "    -> 원격에 $behind 개의 신규 커밋이 있습니다. Pull(rebase) 진행..." -ForegroundColor Magenta
        git -C $scriptDir pull --rebase origin main
    } else {
        Write-Host "    -> 원격 저장소와 최신 상태가 일치합니다." -ForegroundColor Green
    }
} catch {
    Write-Host "    [!] 원격 확인 중 알림: $_" -ForegroundColor Yellow
}

# 2. GEMINI.md 동기화 (개인 계정 경로 일반화)
Write-Host "[2/4] GEMINI.md 전역 규칙 동기화 중..." -ForegroundColor Yellow
$sourceGeminiMd = Join-Path $sourceConfigDir "GEMINI.md"
if (-not (Test-Path $sourceGeminiMd)) {
    $sourceGeminiMd = Join-Path $sourceGeminiDir "GEMINI.md"
}

if (Test-Path $sourceGeminiMd) {
    $geminiContent = Get-Content -Path $sourceGeminiMd -Raw -Encoding UTF8
    # 개인 사용자 경로를 범용 $HOME으로 정규화
    $escapedHome = [regex]::Escape($HOME)
    $normalizedContent = $geminiContent -replace $escapedHome, '$HOME'
    $normalizedContent = $normalizedContent -replace 'C:\\Users\\[^\\]+', '$HOME'
    
    Set-Content -Path $repoGeminiMd -Value $normalizedContent -Encoding UTF8
    Write-Host "    -> GEMINI.md 동기화 및 경로 정규화 완료." -ForegroundColor Green
} else {
    Write-Host "    [!] 경고: 로컬 GEMINI.md 파일을 찾을 수 없습니다." -ForegroundColor Red
}

# 3. 커스텀 스킬 동기화 (skills/)
Write-Host "[3/4] 커스텀 스킬 동기화 중..." -ForegroundColor Yellow
if (Test-Path $sourceSkillsDir) {
    if (-not (Test-Path $repoSkillsDir)) {
        New-Item -ItemType Directory -Path $repoSkillsDir -Force | Out-Null
    }
    
    $skills = Get-ChildItem -Path $sourceSkillsDir -Directory
    $syncedSkillsCount = 0
    
    foreach ($skill in $skills) {
        $skillDest = Join-Path $repoSkillsDir $skill.Name
        if (-not (Test-Path $skillDest)) {
            New-Item -ItemType Directory -Path $skillDest -Force | Out-Null
        }
        
        # 파일 복사 (.bak, .pyc 파일 및 __pycache__ 제외)
        $files = Get-ChildItem -Path $skill.FullName -Recurse -File | Where-Object { 
            $_.Extension -ne '.bak' -and 
            $_.Extension -ne '.pyc' -and 
            $_.FullName -notmatch '__pycache__' 
        }
        foreach ($file in $files) {
            $relPath = $file.FullName.Substring($skill.FullName.Length).TrimStart('\', '/')
            $destFilePath = Join-Path $skillDest $relPath
            $destFileDir = Split-Path -Parent $destFilePath
            if (-not (Test-Path $destFileDir)) {
                New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null
            }
            
            # 변경 여부 확인 후 복사
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
        $syncedSkillsCount++
    }
    Write-Host "    -> $syncedSkillsCount 개 스킬 동기화 완료." -ForegroundColor Green
} else {
    Write-Host "    [!] 경고: 스킬 디렉터리를 찾을 수 없습니다: $sourceSkillsDir" -ForegroundColor Red
}

# 4. 안전 스크립트 동기화 (scripts/)
Write-Host "[4/4] 안전 삭제 스크립트 동기화 중..." -ForegroundColor Yellow
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
                $escapedHome = [regex]::Escape($HOME)
                $normalizedPy = $pyContent -replace $escapedHome, '$HOME'
                $normalizedPy = $normalizedPy -replace 'C:\\Users\\[^\\]+', '$HOME'
                Set-Content -Path $sDest -Value $normalizedPy -Encoding UTF8
            } else {
                Copy-Item -Path $sSource -Destination $sDest -Force
            }
            Write-Host "    -> 스크립트 동기화: $sName" -ForegroundColor Gray
        }
    }
    Write-Host "    -> 안전 스크립트 동기화 완료." -ForegroundColor Green
}

# 5. Git 변경 감지 및 자동 커밋 / 푸시
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
