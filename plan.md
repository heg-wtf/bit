# bit 자동 블로그 글쓰기 자동화 계획

## 목표

heg-wtf 조직의 모든 레포지토리 커밋 메시지를 수집하고, Claude를 활용해 "빌드 인 퍼블릭" 블로그 글을 생성하여 bit.heg.wtf에 배포한다.

## 현재 상태

- heg-wtf 조직: 13개 레포지토리 (bit, hanwoo.heg.wtf, driven.heg.wtf, mustgo.heg.wtf 등)
- bit 프로젝트: 수동 빌드/배포 (`make build` → push)
- 글 포맷: `contents/{YYMMDD}/{YYMMDD}.md` (YAML frontmatter + 한국어 마크다운)

## 구현 파일

| 파일 | 역할 |
|------|------|
| `scripts/collect-commits.sh` | heg-wtf 조직 레포 지난 7일 커밋 수집 → `commits.md` 생성 |
| `scripts/generate-post-prompt.md` | Claude에게 전달할 블로그 글 생성 프롬프트 |
| `scripts/auto-post.sh` | 전체 파이프라인 (수집 → 글 생성 → 빌드 → push) |

## 사용법

### 전체 실행 (한 번에)

```bash
bash scripts/auto-post.sh
```

### 단계별 실행

```bash
# 1. 커밋 수집
bash scripts/collect-commits.sh
cat commits.md

# 2. Claude로 글 생성
claude -p "$(cat scripts/generate-post-prompt.md)"

# 3. 빌드 & 배포
make build
git add contents/ docs/
git commit -m "✨ feat: 주간 빌드인퍼블릭 포스트"
git push origin main
```

## 사전 조건

- `gh` CLI 로그인 상태 (heg-wtf 조직 접근 권한)
- `claude` CLI 로그인 상태 (Pro/Max 구독)
- `uv` 설치 완료

## 자동화 (추후)

수동 실행이 안정적으로 동작하면, macOS launchd 또는 GitHub Actions로 주간 자동 실행 구성 예정.
