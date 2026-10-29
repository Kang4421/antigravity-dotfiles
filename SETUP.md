# Antigravity Environment Setup Guide for AI Agents

이 문서는 새 컴퓨터에서 사용자가 저장소 URL을 제공하며 "환경을 세팅해달라"고 요청했을 때, Antigravity AI가 자율적으로 실행하는 공식 설치 지침(Action Directive)입니다.

---

## 1. 실행 목표 (Objective)
저장소에 포함된 **전역 규칙(`GEMINI.md`)** 및 **커스텀 스킬 12종(`skills/`)**을 현재 컴퓨터의 Antigravity 전역 설정 디렉터리(`~/.gemini/config/`)로 무결점 배포·동기화합니다.

---

## 2. 사전 경로 확인 및 환경 감지
1. 현재 시스템의 사용자 홈 디렉터리 내 Antigravity 설정 경로를 확인합니다:
   - 전역 설정 디렉터리: `$HOME\.gemini\config` (또는 `$env:USERPROFILE\.gemini\config`)
   - 전역 스킬 디렉터리: `$HOME\.gemini\config\skills`
2. 해당 디렉터리가 존재하지 않는 경우 즉시 생성합니다:
   ```powershell
   $configPath = "$HOME\.gemini\config"
   $skillsPath = "$configPath\skills"
   if (-not (Test-Path $skillsPath)) {
       New-Item -ItemType Directory -Path $skillsPath -Force | Out-Null
   }
   ```

---

## 3. 설치 실행 절차 (Installation Procedures)

AI는 아래 **[방법 A]**를 우선 실행하며, 필요시 **[방법 B]**로 직접 복사를 수행할 수 있습니다.

### [방법 A] 동봉된 `install.ps1` 스크립트 실행 (권장)
저장소 루트에서 다음 명령어를 실행하여 일괄 설치 및 검증을 완료합니다:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### [방법 B] 직접 복사 명령어 수행
PowerShell 터미널에서 다음 명령을 순차적으로 실행합니다:
```powershell
# 1. 전역 규칙 GEMINI.md 복제
Copy-Item -Path ".\GEMINI.md" -Destination "$HOME\.gemini\config\GEMINI.md" -Force

# 2. 커스텀 스킬 12종 복제
Copy-Item -Path ".\skills\*" -Destination "$HOME\.gemini\config\skills\" -Recurse -Force
```

---

## 4. 설치 후 자체 검증 (Verification Checklist)
AI는 설치 완료 후 반드시 아래 항목을 터미널로 검증합니다:
1. `$HOME\.gemini\config\GEMINI.md` 파일이 정상적으로 존재하는지 확인
2. `$HOME\.gemini\config\skills\` 내 12개 스킬 디렉터리가 모두 생성되었는지 확인:
   - `artifact-design`, `deep-interview`, `directive-generator`, `execution-plan`
   - `find-skill`, `list-up`, `pdf`, `pptx`
   - `prompt-optimizer`, `reverse-engineer-anything`, `searchmode`, `xlsx`

---

## 5. 사용자 완료 보고 템플릿
모든 설치와 검증이 완료되면 사용자에게 다음 형식으로 간결하게 보고하십시오:

```text
안티그래비티 환경 세팅이 완료되었습니다.
- 전역 룰셋 적용: ~/.gemini/config/GEMINI.md (영구 삭제 방지, 한국어 사고, 스킬 스코프 원칙 등)
- 커스텀 스킬 12종 설치 완료: deep-interview, searchmode, execution-plan 등
* 새로운 대화 세션을 시작하시면 즉시 활성화됩니다.
```
