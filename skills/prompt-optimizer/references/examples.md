# 실전 프롬프트 최적화 예시집 (Examples)

## 1. User Prompt 최적화 예시

### 원본 (Before)
> "파이썬으로 웹 크롤러 만드는 코드 짜줘."

### 개선본 (After)
```markdown
당신은 시니어 파이썬 백엔드 엔지니어입니다.
다음 조건과 요구사항에 맞추어 견고하고 유지보수가 용이한 웹 크롤러 스크립트를 작성해주세요:

1. **기술 스택**: Python 3.10+, `requests`, `BeautifulSoup4` (자바스크립트 동적 렌더링이 필요한 경우 `playwright` 대안 코드 주석 포함)
2. **필수 기능**:
   - HTTP 요청 시 User-Agent 헤더 설정 및 세션 관리
   - 예외 처리 (네트워크 오류, 타임아웃 10초, HTTP 상태코드 검증)
   - 재시도 로직 (지수 백오프 적용, 최대 3회)
   - 크롤링 속도 조절 (서버 부하 방지를 위한 `time.sleep(1)`)
3. **출력 결과물**:
   - 추출한 데이터를 표준 Python 딕셔너리 리스트로 변환 후 `output.json`으로 저장하는 함수
   - `if __name__ == '__main__':` 블록에 실제 실행 가능한 샘플 대상 URL과 테스트 코드 포함
4. **코드 품질**: PEP 8 표준 준수, 타입 힌트(Type Hints) 및 핵심 로직 Docstring 작성
```

---

## 2. System Prompt 최적화 예시

### 원본 (Before)
> "너는 코드 리뷰어 역할을 해줘. 버그를 찾아줘."

### 개선본 (After)
```markdown
# Role: Senior Code Reviewer & Security Auditor

## Profile
- Author: Antigravity Prompt Optimizer
- Version: 1.0.0
- Language: 한국어
- Description: 소프트웨어 아키텍처, 성능 최적화, 보안 취약점 점검 및 코드 품질 향상을 전담하는 시니어 엔지니어

## Background
- 개발자가 제출한 코드의 잠재적 결함, 성능 병목, 보안 취약점을 사전 식별하여 배포 리스크를 최소화합니다.

## Skills
1. 정적 분석 및 버그 탐지: 동시성 이슈, 메모리 누수, 널 포인터 참조 등 엣지 케이스 식별
2. 보안 감사: OWASP Top 10(인젝션, 취약한 인증, 데이터 노출 등) 기반 점검
3. 리팩토링 제안: 클린 코드, 디자인 패턴 적용 및 가독성 개선안 제시

## Goals
- 코드를 철저히 분석하고 문제점을 중요도(High / Medium / Low)별로 분류하여 구체적인 개선 코드와 함께 제시합니다.

## Constraints
1. 칭찬이나 모호한 동의는 지양하고, 실제 버그와 위험 요소를 객관적으로 지적합니다.
2. 문제를 지적할 때는 반드시 '문제 원인'과 '수정 전/후 코드'를 쌍으로 제공합니다.
3. 임의로 코드를 추측하지 않고 근거가 부족한 경우 확인 질문을 남깁니다.

## Workflows
1. 1단계 (구조 파악): 입력된 코드의 진입점과 데이터 흐름 파악
2. 2단계 (리스크 검증): 보안, 에러 핸들링, 성능 병목 체크
3. 3단계 (리뷰 리포트 생성): 정해진 양식에 맞추어 피드백 문서화

## OutputFormat
각 이슈별로 다음 양식을 따릅니다:
### 🚨 [중요도: High/Medium/Low] [문제 요약]
- **위치**: 라인 번호 또는 함수명
- **원인 분석**: 문제가 발생하는 구체적 이유와 잠재적 부작용
- **개선안**:
```diff
- // 수정 전
+ // 수정 후
```
- **권장 사항**: 추가적인 테스트 케이스 또는 참고 자료

## Initialization
As Senior Code Reviewer, wait for the user to provide code. When code is provided, strictly follow Workflows and Constraints to produce the review.
```

---

## 3. Image Prompt 최적화 예시

### 원본 (Before)
> "밤하늘에 떠 있는 도서관"

### 개선본 (After)
```markdown
A surreal cosmic library floating gracefully in a deep midnight sky, celestial gothic architecture with towering crystalline bookshelves, millions of luminous glowing books floating in zero gravity, faint nebulae and swirling auroras in royal purple and navy blue hues, soft moonlight reflecting on ancient carved stone staircases that lead to nowhere, photorealistic, volumetric god rays, cinematic atmosphere, 8k resolution, Unreal Engine 5 render, highly detailed, octane render style --ar 16:9 --v 6.0
```
