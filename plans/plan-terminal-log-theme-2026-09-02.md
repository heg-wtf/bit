# Plan: bit · Terminal Log 테마
- date: 2026-09-02
- status: done
- author: claude
- approved-by: ash84 (시안 A "Terminal Log" 강화판 확정, 2026-09-02)

## 1. 목적 및 배경
- bit.heg.wtf는 직전 PR(#2)에서 heg.wtf와 같은 벤토 테마로 통일했으나, 사용자 판단은 "bit는 원래 컨셉(날것·monospace·타임라인)에서 따로 발전시키는 게 맞다".
- 시안 3종(`claude.ai/code/artifact/df60b82d-…`) 중 **A · Terminal Log** 강화판 확정. `tail -f build.log` 메타포: 타이핑 시퀀스, 로그 포맷 헤더, 문단 줄번호, tmux 상태바, mono 본문(영문 mono + 한글 시스템 폴백).
- 라이트/다크 모두 지원. OS 설정을 따르고 타이틀바 토글로 수동 전환(localStorage 기억).

## 2. 예상 임팩트
- `themes/bit/index.html`, `themes/bit/post.html`, `themes/bit/assets/style.css` 교체 → `make build` 산출물 `docs/` 전체 재생성(40페이지).
- 홈: 요약 카드(#2) → **전문 인라인 타임라인 복원**(원래 컨셉). 홈 HTML 크기는 #2 이전 수준(~150KB)으로 돌아감.
- 포스트 페이지: `less` 뷰어 톤. `q` 키로 홈 복귀.
- 유지: #2의 기능 수정(`/assets` 절대경로, canonical/og:url, 포스트 GA, 콘텐츠 이미지 경로), `Makefile`·`scripts/check_site.py`·테스트, 자동 포스트 파이프라인 인터페이스.
- 외부 리소스: Google Fonts JetBrains Mono 1개(Outfit 제거). Bitcount는 로컬 TTF 유지.
- `contents/`, `scripts/*.sh` 변경 없음.

## 3. 구현 방법 비교
| 방법 | 장점 | 단점 |
|---|---|---|
| A. Jinja 템플릿 + CSS만 교체, 로드 시퀀스는 소량 JS | 빌드 파이프라인 불변, JS 없어도 전문 표시 | 태그는 홈 컨텍스트(`post_list`)에 없어 홈 헤더엔 description을 로그 메시지로 사용 |
| B. zvc 포크해 `post_list`에 tags 추가 | 홈 헤더에 태그 노출 | 의존성 포크 유지 비용. 정적 블로그에 과함 |
| C. 홈에서 JS로 각 포스트 페이지 fetch해 태그 추출 | zvc 불변 | 39회 fetch, JS 의존, 느림 |

**선택: A.** 태그는 포스트 페이지(`tag_list` 제공됨)에서만 표시. 홈 헤더는 `● 날짜 INFO #id — description`.

## 4. 구현 단계
- [x] Step 1: 브랜치 `feat/terminal-log-theme`, plan 문서
- [x] Step 2: `themes/bit/assets/style.css` — 토큰(라이트/다크 + `data-theme` 오버라이드), 타이틀바, 프롬프트/출력, 엔트리(로그 헤더·줄번호 카운터·`- - -` 구분선·메타), tail 커서, tmux 상태바, 포스트 페이지, 반응형, reduced-motion
- [x] Step 3: `themes/bit/index.html` — 헤드 인라인 스크립트(테마 선적용·시퀀스 여부), 타이틀바, 프롬프트, 전문 인라인 엔트리(`<p>--</p>`→`<hr>` Jinja 치환, chars/paragraphs 메타), tail, 상태바, JSON-LD(`post.link`), 시퀀스 JS(세션당 1회)
- [x] Step 4: `themes/bit/post.html` — `less +/id build.log` 프롬프트, 로그 헤더 + 태그, 본문 줄번호, `(END)` 내비, `q` 단축키, 상태바
- [x] Step 5: CLAUDE.md 스타일 설명 갱신
- [x] Step 6: `make build` → `make lint && make test` → 헤드리스 Chrome(홈 다크/라이트, 포스트, 390px)
- [x] Step 7: 커밋, PR

## 5. 테스트 계획
**단위 테스트:** `tests/test_check_site.py` 10건 유지(변경 없음)

**통합 테스트:**
- [x] `make build` 40페이지 생성, 홈 `.entry` 39개
- [x] `make lint` 통과(로컬 자산·앵커·meta)
- [x] 홈 다크/라이트 렌더에서 프롬프트·헤더·줄번호·상태바 대비 정상
- [x] 포스트 페이지 `/assets/style.css` 로드, 태그 표시, `(END)` 내비
- [x] 390px에서 가로 스크롤 없음, 상태바 우측 항목 축약
- [x] JS 비활성 상태에서도 전문 표시(시퀀스는 JS 있을 때만)

## 6. 사이드 이펙트
- **홈 전문 인라인 복원**: #2에서 요약으로 바꾼 것을 되돌림. 개별 페이지는 그대로 있어 URL·SEO 영향 없음 → 대응 완료
- **로드 시퀀스**: 세션당 1회만 실행(`sessionStorage`), reduced-motion 시 생략, URL에 해시(`/#260809` 등 앵커 복귀)가 있으면 생략 → 대응 완료
- **테마 토글**: `localStorage` 실패 시 OS 설정으로 동작(try/catch) → 대응 완료
- **Outfit 제거·JetBrains Mono 추가**: 외부 요청 수 동일 → 해당 없음
- 자동 포스트 파이프라인: `make build`·`contents/` 포맷 불변 → 해당 없음

## 7. 보안 검토
- 정적 HTML, 입력 없음. JS는 클래스 토글·`sessionStorage`/`localStorage`·`q` 키 이동만. → OWASP 해당 없음
- 인증/인가·민감 데이터·PCI-DSS: 해당 없음
- 외부 스크립트: 기존 GA만
