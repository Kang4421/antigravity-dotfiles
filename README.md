# Antigravity Environment Sync Repository

Google Antigravity의 전역 규칙(`GEMINI.md`) 및 실무 검증된 커스텀 스킬 12종을 다른 컴퓨터에 원클릭으로 복제·동기화하기 위한 통합 설정 저장소입니다.

---

## ⚡ 새 컴퓨터에서 AI에게 적용 지시하는 방법 (가장 간편한 방법)

새 컴퓨터에서 안티그래비티(Antigravity)를 켠 후, 대화창에 아래 1줄 지시문(저장소 주소 포함)을 그대로 입력하십시오:

```text
<이_저장소의_깃허브_주소> 저장소를 클론한 뒤, 저장소 내 SETUP.md 지침에 따라 내 컴퓨터의 안티그래비티 전역 환경(~/.gemini/config/)에 규칙과 스킬들을 설치해줘.
```

> **동작 원리**: Antigravity AI가 이 저장소의 [`SETUP.md`](SETUP.md) 지침을 읽고, 현재 PC의 사용자 경로를 스스로 인식하여 전역 규칙과 12종 스킬을 완전 무인으로 자동 배치합니다.

---

## 🛠️ 터미널에서 직접 원클릭 설치하는 방법

PowerShell 터미널에서 직접 실행하려면 아래 명령어를 입력하십시오:

```powershell
# 1. 저장소 클론 (또는 ZIP 다운로드 후 압축 해제)
git clone <이_저장소의_깃허브_주소>.git
cd <저장소_폴더명>

# 2. 원클릭 설치 스크립트 실행
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

---

## 📦 패키징된 구성 요소

### 1. 전역 규칙 (`GEMINI.md`)
- **파일/폴더 영구 삭제 절대 금지 및 휴지통 이동 의무화**: `rm`, `Remove-Item` 등의 영구 삭제 명령을 원천 차단하고 Windows 휴지통으로 안전 격리
- **한국어 사고 과정(Thinking Process)**: 모든 판단 및 추론 과정을 한국어로 진행
- **스킬 및 에이전트 로컬 스코프 원칙**: 프로젝트 작업 시 전역 설정 오염을 방지하고 워크스페이스 로컬 스코프 최우선 등록
- **실사 의무 및 웹 검색 규약**: 사실 확인 우선 및 딥 리서치 규격 준수

### 2. 커스텀 스킬 12종 (`skills/`)
1. **`artifact-design`**: 단독 정적 HTML/CSS 웹 산출물 전용 디자인 가이드
2. **`deep-interview`**: 소크라테스식 1문 1답 모호성 소거 기반 요구사항 구체화 엔진
3. **`directive-generator`**: 군더더기 없는 고밀도 명령형 실행 지시문 생성기
4. **`execution-plan`**: 사전 실사 및 승인 게이트 기반 범용 작업 플래닝 엔진
5. **`find-skill`**: 외부 스킬을 탐색하여 Antigravity 표준 규격으로 변환/설치
6. **`list-up`**: 특정 주제 대안/아이디어를 표 형태로 20~30개 전수 발산
7. **`pdf`**: PDF 텍스트/표 추출, 병합, 분할, OCR 등 전주기 처리 스킬
8. **`pptx`**: 프레젠테이션 슬라이드 생성, 편집, 파싱 전문 스킬
9. **`prompt-optimizer`**: 프롬프트 구조화, 고도화 및 69종 직무 프리셋 지원
10. **`reverse-engineer-anything`**: 네이티브, 웹, 바이너리 리버스 엔지니어링 분석 스킬
11. **`searchmode`**: 증거 우선 팩트체크 및 딥 리서치 엔진
12. **`xlsx`**: 스프레드시트(.xlsx, .csv) 생성, 수식 계산, 클렌징 처리 스킬

---

## 🚀 깃허브 원격 저장소 연결 및 푸시 가이드

GitHub 웹사이트에서 빈 새 리포지토리(New repository)를 생성한 후, 이 폴더(`Desktop\github`)의 PowerShell에서 아래 명령을 실행하십시오:

```powershell
# main 브랜치 지정
git branch -M main

# 깃허브 원격 저장소 연결 (본인의 깃허브 URL 입력)
git remote add origin https://github.com/<사용자ID>/<저장소명>.git

# 원격 저장소로 업로드
git push -u origin main
```
