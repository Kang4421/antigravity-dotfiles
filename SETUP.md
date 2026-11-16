# Antigravity Environment Setup Guide for AI Agents

이 문서는 새 컴퓨터에서 사용자가 저장소 URL을 제공하며 "환경을 세팅해달라"고 요청했을 때, Antigravity AI가 자율적으로 실행하는 공식 설치 지침(Action Directive)입니다.

---

## 1. 실행 목표 (Objective)
저장소에 포함된 다음 구성 요소를 현재 컴퓨터의 Antigravity 전역 환경으로 배포·동기화하고, 외부 필수 의존성(`ego-browser` 등)의 설치 여부를 점검합니다:
1. **전역 규칙 (`GEMINI.md`)**: 영구 삭제 금지 및 휴지통 이동 의무화, 한국어 기본 응답, `searchmode` & `ego-browser` 하이브리드 브라우징 규약, 스킬/에이전트 로컬 스코프 원칙
2. **커스텀 스킬 14종 (`skills/`)**: `deep-interview`, `directive-generator`, `ego-browser`, `execution-plan`, `export-transcript`, `find-skill`, `list-up`, `pdf`, `pptx`, `reverse-engineer-anything`, `searchmode`, `vibe-audit`, `vibe-verify`, `xlsx`
3. **안전 삭제 유틸리티 (`scripts/`)**: `recycle.ps1`, `recycle.cmd`, `check_delete_guard.py`
4. **영구 삭제 방지 가드 훅 (`hooks.json`)**: `run_command` 실행 전 영구 삭제 패턴 차단 훅
5. **전역 사용자 설정 템플릿 (`config.template.json`)**: Antigravity `userSettings` (Review/Auto-Execution/Browser JS 정책, 테마, 허용 URL 목록 등 — 기기별 호스트명 및 시크릿 제외)

---

## 2. 새 컴퓨터 필수 사전/후속 프로그램 (Prerequisites)

설정 파일 복제만으로는 외부 바이너리와 런타임이 설치되지 않으므로, 아래 항목의 설치 여부를 반드시 확인하고 미설치 항목은 사용자에게 안내하거나 설치를 진행해야 합니다.

### 2-1. `ego-browser` (ego lite) — 웹 자동화 및 하이브리드 브라우징 필수
- `GEMINI.md`의 웹 검색·브라우징 하이브리드 규약과 `ego-browser`, `vibe-audit`, `vibe-verify` 스킬은 **ego lite** 앱이 제공하는 `ego-browser` CLI에 의존합니다.
- 저장소 내 `skills/ego-browser`는 부트스트랩 및 레퍼런스 스킬이며, 실제 브라우저와 CLI는 별도 설치가 필요합니다.
- **Windows 설치 및 온보딩 절차** (`skills/ego-browser/references/install-windows.md` 기준):
  1. `https://lite.ego.app/` 에서 Windows용 설치 파일을 다운로드하여 실행합니다. (Windows SmartScreen 경고가 표시되면 `추가 정보` -> `실행` 선택)
  2. 설치된 **ego lite** 앱을 실행하고 GUI에서 **초기 온보딩(Onboarding)**을 완료합니다. (온보딩 과정에서 `ego-browser` 명령이 사용자 `PATH`에 등록됩니다.)
  3. 온보딩 완료 후 **새 터미널**을 열어 아래 3개 명령으로 정상 동작을 검증합니다:
     ```powershell
     Get-Command ego-browser
     ego-browser nodejs -e "console.log('ego-browser ready')"
     ego-browser skill
     ```
  - 참고: 이미 ego lite가 설치되어 있으나 업데이트 직후 `ego-browser`가 인식되지 않는 경우, ego lite 앱을 1회 다시 실행하거나 `$HOME\.local\share\ego\active_version_dir` 경로가 실제 설치 버전을 가리키는지 확인하십시오.

### 2-2. Python 3, Git, Node.js
- **Python 3 (`python`)**: `hooks.json`의 `check_delete_guard.py` 영구 삭제 차단 훅과 `export-transcript`, `pdf`, `pptx`, `xlsx` 스킬 실행에 **필수**입니다. (`PATH` 등록 필요)
- **Git (`git`)**: 저장소 클론 및 `update_and_push.bat` 양방향 동기화에 필수입니다.
- **Node.js (`node` / `npx`)**: 선택적 MCP 서버(`rea` 등) 실행에 필요합니다.

---

## 3. 사전 경로 확인 및 디렉터리 준비
1. 현재 시스템의 사용자 홈 디렉터리 내 Antigravity 설정 경로를 확인합니다:
   - 전역 루트 디렉터리: `$HOME\.gemini`
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

## 4. 설치 실행 절차 (Installation Procedures)

AI는 아래 **[방법 A]**를 우선 실행하며, 필요시 **[방법 B]**로 직접 복사를 수행할 수 있습니다.

### [방법 A] 동봉된 `install.ps1` 스크립트 실행 (권장)
저장소 루트에서 다음 명령어를 실행하여 규칙·스킬·스크립트·훅·`userSettings` 병합, `PATH` 등록 및 사전 요구사항 점검을 일괄 수행합니다:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### [방법 B] 직접 복사 및 환경 구성 수행
PowerShell 터미널에서 다음 명령을 순차적으로 실행합니다:
```powershell
$targetGemini = "$HOME\.gemini"
$targetConfig = "$HOME\.gemini\config"
$targetSkills = "$targetConfig\skills"
$targetScripts = "$HOME\.gemini\scripts"

# 1. 전역 규칙 GEMINI.md 복제 (상위 ~/.gemini 및 ~/.gemini/config 양쪽 일치)
Copy-Item -Path ".\GEMINI.md" -Destination "$targetGemini\GEMINI.md" -Force
Copy-Item -Path ".\GEMINI.md" -Destination "$targetConfig\GEMINI.md" -Force

# 2. 커스텀 스킬 14종 복제 (기존 ego-browser 유효 링크는 유지 가능)
Get-ChildItem -Path ".\skills" -Directory | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $targetSkills -Recurse -Force
}

# 3. 안전 삭제 스크립트 복제
Copy-Item -Path ".\scripts\*" -Destination $targetScripts -Force

# 4. hooks.json 경로 치환 및 복제
$hookContent = (Get-Content ".\hooks.json" -Raw -Encoding UTF8).Replace("{{SCRIPTS_DIR}}", ($targetScripts -replace '\\', '\\\\'))
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$targetGemini\hooks.json", $hookContent, $utf8NoBom)
[System.IO.File]::WriteAllText("$targetConfig\hooks.json", $hookContent, $utf8NoBom)

# 5. User PATH에 scripts 디렉터리 등록
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$targetScripts*") {
    [Environment]::SetEnvironmentVariable("Path", "$($userPath.TrimEnd(';'));$targetScripts", "User")
}
```
> `config.template.json`의 `userSettings`를 기존 `$HOME\.gemini\config\config.json`과 비파괴적으로 병합하려면 `install.ps1` 실행을 권장합니다.

---

## 5. 선택적 MCP 및 보안 제외 항목 안내

아래 항목은 보안(개인 토큰/인증 정보) 또는 기기 종속성 때문에 저장소에 포함되지 않습니다:
- **제외 파일**: `oauth_creds.json`, `google_accounts.json`, `mcp_config.json*`, `settings.json*`, `projects.json`, `state.json`, `trustedFolders.json`
- **REA MCP (`reverse-engineer-anything` 스킬용)**:
  새 컴퓨터에서 바이너리/Electron 리버스 엔지니어링 MCP가 필요하다면 아래 명령으로 등록하십시오:
  ```powershell
  npx -y rea-agents setup --client antigravity
  ```
- **기타 개인 MCP 서버 (예: `naver-mybox` 등)**: 개인 PAT 토큰이나 로컬 서버 경로가 포함되므로 새 컴퓨터의 `$HOME\.gemini\config\mcp_config.json`에서 개별 재등록이 필요합니다.

---

## 6. 설치 후 자체 검증 (Verification Checklist)
AI는 설치 완료 후 반드시 아래 항목을 터미널로 검증합니다:
1. `$HOME\.gemini\GEMINI.md` 및 `$HOME\.gemini\config\GEMINI.md` 파일 존재 및 내용 일치 확인
2. `$HOME\.gemini\config\skills\` 내 14개 스킬 디렉터리가 모두 존재하는지 확인:
   - `deep-interview`, `directive-generator`, `ego-browser`, `execution-plan`
   - `export-transcript`, `find-skill`, `list-up`, `pdf`, `pptx`
   - `reverse-engineer-anything`, `searchmode`, `vibe-audit`, `vibe-verify`, `xlsx`
3. `$HOME\.gemini\scripts\` 내 스크립트 3종(`recycle.ps1`, `recycle.cmd`, `check_delete_guard.py`) 존재 확인
4. `$HOME\.gemini\hooks.json` 및 `$HOME\.gemini\config\hooks.json` 파일 존재 및 경로 유효성 확인
5. `$HOME\.gemini\config\config.json` 내 `userSettings` 적용 확인
6. 외부 필수 도구 확인:
   - `Get-Command python`
   - `Get-Command ego-browser` (미설치 시 반드시 사용자에게 `https://lite.ego.app/` 설치 및 온보딩 진행 안내)

---

## 7. 사용자 완료 보고 템플릿
모든 설치와 검증이 완료되면 사용자에게 다음 형식으로 간결하게 보고하십시오 (`ego-browser` 미설치 시 안내 포함):

```text
안티그래비티 환경 세팅이 완료되었습니다.
- 전역 규칙 적용: ~/.gemini/GEMINI.md & ~/.gemini/config/GEMINI.md (영구 삭제 방지, 한국어 응답, searchmode & ego-browser 하이브리드 규약, 스킬 로컬 스코프 원칙)
- 커스텀 스킬 14종 설치 완료: deep-interview, searchmode, execution-plan, vibe-audit, vibe-verify, ego-browser 등
- 안전 유틸리티 및 가드 훅 배치: ~/.gemini/scripts/ (recycle 명령어, PreToolUse 영구 삭제 차단 훅)
- 전역 설정(userSettings) 병합 완료: ~/.gemini/config/config.json
- 사전 도구 점검:
  * Python: [확인됨 / 미설치]
  * ego-browser (ego lite): [확인됨 / 미설치 -> https://lite.ego.app/ 설치 및 온보딩 필요]
* 새로운 대화 세션을 시작하시면 설정이 즉시 반영됩니다.
```
