# External Skill Sources & Conversion Reference

## 1. Primary Repositories & Hubs

외부 스킬을 탐색할 때 우선적으로 검색할 주요 허브와 저장소입니다:

### GitHub Repositories
- **agentic-awesome-skills**: `https://github.com/sickn33/agentic-awesome-skills`
  - 수천 개의 커뮤니티 에이전트 스킬, Claude Code 호환 스킬, 역할별 템플릿 포함.
- **antigravity-skills**: `https://github.com/rmyndharis/antigravity-skills`
  - Antigravity 규격에 최적화된 큐레이션 스킬 모음.
- **awesome-cursorrules**: `https://github.com/PatrickJS/awesome-cursorrules`
  - 프레임워크 및 언어별 베스트 프랙티스 규칙(Cursor rules). 스킬로 변환하기 적합.

### Directory & Hubs
- **SkillsLLM**: `https://skillsllm.com`
  - 에이전트 스킬 검색 및 평가 디렉터리.
- **Skills Hub**: `https://api.skills-hub.ai`
  - MCP 연동 스킬 레지스트리.

---

## 2. Search Query Strategies

`search_web` 도구를 사용할 때 효과적인 쿼리 패턴:

```text
site:github.com "SKILL.md" "<keyword>"
site:github.com/sickn33/agentic-awesome-skills "<keyword>"
site:github.com/rmyndharis/antigravity-skills "<keyword>"
site:github.com "CLAUDE.md" OR ".cursorrules" "<keyword>" "workflow"
skillsllm.com "<keyword>"
```

---

## 3. Format Conversion Guide (To Antigravity SKILL.md)

### A. Cursor Rules (`.cursorrules` or `.mdc`) -> Antigravity Skill
- **특징**: 주로 특정 프레임워크(React, NestJS 등)의 코딩 컨벤션 위주.
- **변환 방식**:
  - `name`: `framework-best-practices` 또는 `<domain>-guidelines`
  - `description`: "Use this skill when developing or reviewing <framework> code..." (적극적 트리거)
  - 본문: 단계별 작업 절차(Workflow)와 금기 사항/권장 사항으로 체계화.

### B. Claude Code (`CLAUDE.md` or Prompts) -> Antigravity Skill
- **특징**: 빌드/테스트 명령어 및 프로젝트 컨텍스트 포함.
- **변환 방식**:
  - 프로젝트 특화 정보는 제거하고 범용적인 에이전트 절차로 일반화.
  - Antigravity 도구(`run_command`, `replace_file_content`, `grep_search` 등)의 사용 지침에 맞게 정렬.

### C. 일반 프롬프트 / 시스템 프롬프트 -> Antigravity Skill
- 단순 "역할극(Persona)" 지침을 "구체적인 작업 절차(Step-by-step Workflow)"로 재구성.
- 입력값 검증, 중간 산출물 검토, 최종 검증(Verification) 단계를 추가하여 에이전틱하게 개선.
