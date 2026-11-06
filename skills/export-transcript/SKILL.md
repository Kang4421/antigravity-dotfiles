---
name: export-transcript
description: |
  현재 세션 또는 과거 대화 세션의 transcript(대화 로그 .jsonl)를 AI의 내부 사고 과정(Thinking / Chain of Thought)을 100% 보존하면서
  깔끔하게 구조화된 마크다운(.md) 파일로 변환하여 바탕화면 또는 지정 경로로 내보내는 전용 스킬.
  중복 파일 전문/시스템 메타데이터를 제거하여 토큰을 50% 이상 절약하는 Compact 모드와 전체 원시 로그를 수록하는 Full 모드를 지원한다.
  사용자가 "transcript 내보내줘", "대화 기록 저장해줘", "대화 추출해줘", "이 대화 md로 저장", "transcript md 변환",
  "AI 생각 포함해서 대화 저장", "/export-transcript", "expert-chat", "대화 내보내기" 등을 요청할 때 활성화한다.
argument-hint: "[--compact|--full] [--output <경로>] [@conversation:<대화명> | <대화ID> | <jsonl경로> | 'current']"
---

# Export Transcript (대화 기록 및 AI 사고 추출 엔진)

이 스킬은 Antigravity의 대화 트랜스크립트(`transcript_full.jsonl` / `transcript.jsonl`)를 **AI의 내부 사고 과정(Thinking / Chain of Thought)을 온전히 포함한 고품질 마크다운(.md)** 문서로 변환하여 내보냅니다.

---

## 🚀 빠른 실행 (Execution Protocol)

에이전트는 사용자의 요청 접수 시 내장된 파이썬 스크립트를 `run_command`로 호출하여 즉각 변환을 수행합니다.

### 1. 기본 실행 명령어 (스크립트 위치)
```powershell
python "C:\Users\KangHyeonwoo\.gemini\config\skills\export-transcript\scripts\export_transcript.py" --input "<대상>" [--output "<출력_MD_경로>"] [--mode compact|full] [--title "<문서_제목>"]
```

### 2. 인자별 처리 기준 (`--input`)
- **현재 진행 중인 대화**: 현재 세션의 Conversation ID(시스템 프롬프트의 `<user_information>` 내 Conversation ID)를 전달
  - 예: `--input "80ecc724-5cae-4843-aee0-a7cb7f1f8ee2"`
- **과거 대화 링크/참조**: `@conversation:"Title"` 또는 `conversation://<UUID>`가 주어지면 해당 UUID를 전달
  - 예: `--input "60468a7b-257c-4491-9074-4580fa4991e9"`
  - UUID를 모를 경우 대화 제목 키워드로 검색 가능: `--input "Outfit Coordination Tips"`
- **로컬 파일 직접 지정**: `.jsonl` 파일 경로 직접 전달
  - 예: `--input "C:\Users\KangHyeonwoo\Desktop\transcript_full.jsonl"`

---

## ⚙️ 내보내기 모드 (Modes)

### 1. `compact` 모드 (기본 권장, `--mode compact`)
- **토큰 50% 이상 절약**: 불필요한 시스템 메타데이터(`<ADDITIONAL_METADATA>`, `<USER_SETTINGS_CHANGE>`, 시스템 내부 주입 프롬프트) 제거.
- **도구 실행 압축**: 수만 자에 달하는 `read_file(SKILL.md)` 전문이나 검색 결과 원문을 1줄 핵심 요약(`- 🛠️ read_file(SKILL.md): 파일 내용 확인 완료`)으로 정돈.
- **🧠 AI Thinking 100% 보존**: AI의 추론 및 판단 근거(CoT)는 단 한 줄도 유실 없이 마크다운 인용구(`>`) 형태로 온전히 유지.
- **출력 위치**: 기본값은 바탕화면 (`C:\Users\KangHyeonwoo\Desktop\<대화제목>.md`).

### 2. `full` 모드 (`--mode full`)
- 사용자가 "도구 호출 원본 데이터까지 다 보고 싶다", "전체 로그 다 남겨줘"라고 요구할 때 사용.
- 도구 호출 파라미터 JSON 및 실행 원시 결과를 `<details>` 접이식 태그로 완전 수록.

---

## 📋 변환 결과 마크다운 문서 표준 구조

1. **상단 메타데이터 요약 블록 (`> [!NOTE]`)**: Conversation ID, 총 대화 턴 수, 총 스텝 수, 시작/종료 시각 (KST 한국 시간 기준).
2. **목차 (Table of Contents)**: 각 대화 턴의 핵심 질문 요약 및 클릭 시 즉시 이동하는 앵커 링크.
3. **대화 턴 블록**:
   - `👤 User`: 사용자 실제 요청 본문
   - `🧠 AI Thinking`: AI 모델의 내부 사고 과정 (Chain of Thought)
   - `🛠️ 실행된 도구`: 도구 호출 내역 및 결과 요약
   - `🤖 Assistant Response`: 최종 사용자 전달 응답 본문

---

## 🔒 안전 및 파일 처리 원칙
- 생성된 마크다운 파일은 사용자 바탕화면 또는 요청된 지정 경로에 저장하며, 완료 후 클릭 가능한 파일 링크(`[파일명](file:///...)`)를 사용자에게 안내합니다.
- 임시 파일이나 기존 파일 정리 시 시스템 삭제 규칙(영구 삭제 금지, Windows 휴지통 이동 `recycle`)을 반드시 준수합니다.
