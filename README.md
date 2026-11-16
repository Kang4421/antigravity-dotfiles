# Antigravity Environment Sync Repository

Google Antigravity의 전역 규칙(`GEMINI.md`), 커스텀 스킬 14종, 안전 삭제 유틸리티·가드 훅, 전역 사용자 설정 템플릿(`config.template.json`)을 다른 컴퓨터에 복제·동기화하기 위한 통합 설정 저장소입니다.

---

## 새 컴퓨터에서 AI에게 적용 지시하는 방법 (가장 간편한 방법)

새 컴퓨터에서 Antigravity를 실행한 뒤, 대화창에 아래 지시문을 입력하십시오:

```text
https://github.com/Kang4421/antigravity-dotfiles.git 저장소를 클론한 뒤, 저장소 내 SETUP.md 지침에 따라 내 컴퓨터의 안티그래비티 전역 환경(~/.gemini/)에 규칙, 스킬, 스크립트, 설정을 설치하고 ego-browser 등 누락된 필수 프로그램이 있으면 안내해줘.
```

> **동작 원리**: Antigravity AI가 [`SETUP.md`](SETUP.md) 지침을 읽고 현재 PC 경로를 인식하여 전역 규칙, 14종 스킬, 안전 삭제 스크립트, 가드 훅, `userSettings`를 배치한 뒤 Python·`ego-browser` 설치 상태까지 점검합니다.

---

## 터미널에서 직접 원클릭 설치하는 방법

PowerShell 터미널에서 직접 실행하려면 아래 명령어를 입력하십시오:

```powershell
# 1. 저장소 클론
git clone https://github.com/Kang4421/antigravity-dotfiles.git
cd antigravity-dotfiles

# 2. 원클릭 설치 스크립트 실행
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

---

## 새 컴퓨터에서 추가로 설치해야 하는 필수 프로그램

설정 파일 동기화 외에 아래 프로그램들이 새 컴퓨터에 설치되어 있어야 모든 규칙과 스킬이 정상 동작합니다.

1. **`ego-browser` (ego lite) — 웹 자동화 및 하이브리드 브라우징 필수**
   - `GEMINI.md`의 웹 검색·브라우징 규약 및 `ego-browser`, `vibe-audit`, `vibe-verify` 스킬이 사용합니다.
   - 설치 방법:
     1. `https://lite.ego.app/` 에서 Windows 설치 파일을 받아 설치합니다.
     2. **ego lite** 앱을 실행하고 GUI 초기 온보딩을 완료합니다 (`ego-browser` 명령이 `PATH`에 등록됨).
     3. 새 터미널을 열고 아래 명령으로 확인합니다:
        ```powershell
        Get-Command ego-browser
        ego-browser nodejs -e "console.log('ego-browser ready')"
        ego-browser skill
        ```
2. **Python 3** — **필수** (`check_delete_guard.py` 영구 삭제 차단 훅 및 `export-transcript`, `pdf`, `pptx`, `xlsx` 스킬 동작에 필요)
3. **Git** & **Node.js** — 저장소 동기화(`update_and_push.bat`) 및 선택적 MCP(`npx`) 실행에 필요
4. **(선택) REA MCP 서버 (`reverse-engineer-anything` 스킬용)**:
   ```powershell
   npx -y rea-agents setup --client antigravity
   ```

---

## 패키징된 구성 요소

### 1. 전역 규칙 (`GEMINI.md`)
- **파일/폴더 영구 삭제 절대 금지 및 휴지통 이동 의무화**: `rm`, `Remove-Item` 등의 영구 삭제 명령을 차단하고 Windows 휴지통(`recycle`)으로 안전 격리
- **기본 응답 언어 및 검증 원칙**: 한국어 응답, 추측 배제, 팩트 선검증
- **웹 검색 및 브라우징 하이브리드 규약**: 정적 정보는 `searchmode` / `search_web`, 상호작용·SPA·심층 웹 조사는 `ego-browser` 우선 투입
- **스킬 및 에이전트 로컬 스코프 원칙**: 명시적 요청 없이는 전역 오염을 방지하고 프로젝트 로컬 `.agents/` 최우선 등록

### 2. 커스텀 스킬 14종 (`skills/`)
1. **`deep-interview`**: 소크라테스식 1문 1답 모호성 소거 기반 요구사항 구체화 엔진
2. **`directive-generator`**: 군더더기 없는 고밀도 명령형 실행 지시문 생성기
3. **`ego-browser`**: ego lite 브라우저 자동화 및 실화면 브라우징 제어 스킬 (v2.2.1)
4. **`execution-plan`**: 사전 실사 및 승인 게이트 기반 범용 작업 플래닝 엔진
5. **`export-transcript`**: 대화 로그(`.jsonl`)를 AI 내부 사고 과정(Thinking) 포함 마크다운(`.md`)으로 내보내는 스킬
6. **`find-skill`**: 외부 스킬을 탐색하여 Antigravity 표준 규격으로 변환/설치
7. **`list-up`**: 특정 주제 대안/아이디어를 표 형태로 20~30개 전수 발산
8. **`pdf`**: PDF 텍스트/표 추출, 병합, 분할, OCR 등 전주기 처리 스킬
9. **`pptx`**: 프레젠테이션 슬라이드 생성, 편집, 파싱 전문 스킬
10. **`reverse-engineer-anything`**: 네이티브, Electron/JS, 웹, 바이너리 리버스 엔지니어링 분석 스킬
11. **`searchmode`**: 증거 우선 팩트체크 및 딥 리서치 엔진
12. **`vibe-audit`**: 프로젝트 의도 역추적부터 실화면/API 전방위 실측 QA까지 수행하는 자율 종합 감사 스킬
13. **`vibe-verify`**: 빌드·기동·실화면·콘솔 에러 실측 검증 및 자동 수정(Auto-fix) 검증 스킬
14. **`xlsx`**: 스프레드시트(`.xlsx`, `.csv`) 생성, 수식 계산, 클렌징 처리 스킬

### 3. 안전 삭제 유틸리티 및 가드 훅 (`scripts/`, `hooks.json`)
- **`recycle.ps1` / `recycle.cmd`**: 영구 삭제 대신 Windows 휴지통으로 안전하게 이동시키는 명령어 스크립트
- **`check_delete_guard.py`**: `run_command` 실행 전 `rm`, `Remove-Item` 등의 영구 삭제 패턴을 사전 감지하여 차단
- **`hooks.json`**: Antigravity `PreToolUse` 보안 훅 설정 (설치 시 대상 PC 경로에 맞게 자동 바인딩)

### 4. 전역 사용자 설정 템플릿 (`config.template.json`)
- `~/.gemini/config/config.json`의 `userSettings` (Artifact/AutoExecution/BrowserJS 정책, 테마, 허용 URL 목록 등)만 안전하게 추출한 템플릿입니다.
- 기기별 호스트명(`remoteControlHostname`), 세션 상태(`sidecars`), 개인 인증/토큰(`mcp_config.json`, `oauth_creds.json`, `settings.json`)은 보안상 제외됩니다.

---

## 원클릭 자동 업데이트 및 깃허브 푸시 (`update_and_push.bat`)

내 컴퓨터의 Antigravity 전역 설정(`~/.gemini/`)이 변경되었을 때 폴더 내 **`update_and_push.bat`** 파일을 실행하면 아래 작업이 자동으로 완료됩니다:

1. 원격 최신 커밋 확인 및 병합 (`git pull --rebase origin main`)
2. `~/.gemini/config/GEMINI.md` 전역 규칙 동기화 및 `$HOME` 경로 정규화
3. `~/.gemini/config/skills/` 내 커스텀 스킬 최신화 (`ego-browser` 링크 폴백 및 `$HOME` 경로 정규화 포함)
4. `~/.gemini/scripts/` 안전 스크립트 및 `~/.gemini/config/config.json`의 `userSettings` 템플릿 동기화
5. 변경사항 자동 커밋 및 원격 저장소(`origin/main`) 푸시
