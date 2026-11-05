# Antigravity Environment Setup Guide for AI Agents

이 문서는 새 컴퓨터에서 사용자가 저장소 URL을 제공하며 "환경을 세팅해달라"고 요청했을 때, Antigravity AI가 자율적으로 실행하는 공식 설치 지침(Action Directive)입니다.

---

## 1. 실행 목표 (Objective)
저장소에 포함된 다음 구성 요소를 현재 컴퓨터의 Antigravity 전역 환경으로 무결점 배포·동기화합니다:
1. **전역 규칙 (`GEMINI.md`)**: 영구 삭제 금지, 휴지통 이동 의무화, 한국어 사고, 스킬 로컬 스코프 원칙 등
2. **커스텀 스킬 12종 (`skills/`)**: deep-interview (v6.6), searchmode, execution-plan 등
3. **안전 삭제 유틸리티 (`scripts/`)**: `recycle.ps1`, `recycle.cmd`, `check_delete_guard.py`
4. **영구 삭제 방지 가드 훅 (`hooks.json`)**: `run_command` 실행 전 영구 삭제 패턴 차단 훅

---

## 2. 사전 경로 확인 및 환경 감지
1. 현재 시스템의 사용자 홈 디렉터리 내 Antigravity 설정 경로를 확인합니다:
   - 전역 설정 디렉터리: `$HOME\.gemini\config`
   - 전역 스킬 디렉터리: `$HOME\.gemini\config\skills`
   - 전역 스크립트 디렉터리: `$HOME\.gemini\scripts`
2. 해당 디렉터리가 존재하지 않는 경우 즉시 생성합니다:
   ```powershell
   $configPath = "$HOME\.gemini\config"
   $skillsPath = "$configPath\skills"
   $scriptsPath = "$HOME\.gemini\scripts"
   foreach ($dir in @($configPath, $skillsPath, $scriptsPath)) {
       if (-not (Test-Path $dir)) {
           New-Item -ItemType Directory -Path $dir -Force | Out-Null
       }
   }
   ```

---

## 3. 설치 실행 절차 (Installation Procedures)

AI는 아래 **[방법 A]**를 우선 실행하며, 필요시 **[방법 B]**로 직접 복사를 수행할 수 있습니다.

### [방법 A] 동봉된 `install.ps1` 스크립트 실행 (권장)
저장소 루트에서 다음 명령어를 실행하여 일괄 설치, 경로 치환, PATH 등록 및 검증을 완료합니다:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### [방법 B] 직접 복사 및 환경 구성 수행
PowerShell 터미널에서 다음 명령을 순차적으로 실행합니다:
```powershell
$targetGemini = "$HOME\.gemini"
$targetConfig = "$HOME\.gemini\config"
$targetScripts = "$HOME\.gemini\scripts"

# 1. 전역 규칙 GEMINI.md 복제
Copy-Item -Path ".\GEMINI.md" -Destination "$targetConfig\GEMINI.md" -Force
Copy-Item -Path ".\GEMINI.md" -Destination "$targetGemini\GEMINI.md" -Force

# 2. 커스텀 스킬 12종 복제
Copy-Item -Path ".\skills\*" -Destination "$targetConfig\skills\" -Recurse -Force

# 3. 안전 삭제 스크립트 복제
Copy-Item -Path ".\scripts\*" -Destination "$targetScripts\" -Force

# 4. hooks.json 경로 치환 및 복제
$hookContent = (Get-Content ".\hooks.json" -Raw -Encoding UTF8).Replace("{{SCRIPTS_DIR}}", ($targetScripts -replace '\\', '\\\\'))
Set-Content -Path "$targetGemini\hooks.json" -Value $hookContent -Encoding UTF8
Set-Content -Path "$targetConfig\hooks.json" -Value $hookContent -Encoding UTF8

# 5. User PATH에 scripts 디렉터리 등록
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$targetScripts*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$targetScripts", "User")
}
```

---

## 4. 설치 후 자체 검증 (Verification Checklist)
AI는 설치 완료 후 반드시 아래 항목을 터미널로 검증합니다:
1. `$HOME\.gemini\config\GEMINI.md` 및 `$HOME\.gemini\GEMINI.md` 파일 존재 확인
2. `$HOME\.gemini\config\skills\` 내 12개 스킬 디렉터리가 모두 생성되었는지 확인:
   - `artifact-design`, `deep-interview`, `directive-generator`, `execution-plan`
   - `find-skill`, `list-up`, `pdf`, `pptx`
   - `prompt-optimizer`, `reverse-engineer-anything`, `searchmode`, `xlsx`
3. `$HOME\.gemini\scripts\` 내 스크립트 3종(`recycle.ps1`, `recycle.cmd`, `check_delete_guard.py`) 존재 확인
4. `$HOME\.gemini\hooks.json` 및 `$HOME\.gemini\config\hooks.json` 파일 존재 및 경로 유효성 확인

---

## 5. 사용자 완료 보고 템플릿
모든 설치와 검증이 완료되면 사용자에게 다음 형식으로 간결하게 보고하십시오:

```text
안티그래비티 환경 세팅이 완료되었습니다.
- 전역 규칙 적용: ~/.gemini/config/GEMINI.md (영구 삭제 방지, 한국어 사고, 스킬 스코프 원칙 등)
- 커스텀 스킬 12종 설치 완료: deep-interview (v6.6), searchmode, execution-plan 등
- 안전 유틸리티 및 가드 훅 배치: ~/.gemini/scripts/ (recycle 명령어, PreToolUse 영구 삭제 차단 훅 활성화)
* 새로운 대화 세션을 시작하시면 즉시 활성화됩니다.
```
