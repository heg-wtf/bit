#!/bin/bash
# heg-wtf 조직의 모든 레포에서 지난 7일간 커밋을 수집
# GITHUB_TOKEN 환경변수 또는 .env 파일에서 토큰을 읽어서 GitHub API 직접 호출
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# .env 파일이 있으면 로드
if [ -f "$PROJECT_DIR/.env" ]; then
  source "$PROJECT_DIR/.env"
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN이 설정되지 않았습니다."
  echo ".env 파일에 GITHUB_TOKEN=ghp_xxx 형태로 추가하거나, 환경변수로 설정해주세요."
  exit 1
fi

ORGANIZATION="heg-wtf"
SINCE=$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)
UNTIL=$(date -u +%Y-%m-%dT%H:%M:%SZ)
OUTPUT="$PROJECT_DIR/commits.md"
API_BASE="https://api.github.com"

echo "# heg-wtf 주간 커밋 요약" > "$OUTPUT"
echo "기간: $(date -u -v-7d +%Y-%m-%d) ~ $(date -u +%Y-%m-%d)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

has_commits=false

# 조직의 레포 목록 가져오기
repos=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "$API_BASE/orgs/$ORGANIZATION/repos?per_page=100" \
  | python3 -c "import sys,json; [print(r['name']) for r in json.load(sys.stdin)]")

for repo in $repos; do
  # bit 레포 자체는 제외 (자동생성 글 커밋 순환 방지)
  if [ "$repo" = "bit" ]; then continue; fi

  commits=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "$API_BASE/repos/$ORGANIZATION/$repo/commits?since=$SINCE&until=$UNTIL&per_page=100" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
if isinstance(data, list):
    for c in data:
        msg = c['commit']['message'].split('\n')[0]
        print(f'- {msg}')
" 2>/dev/null || true)

  if [ -n "$commits" ]; then
    echo "## $repo" >> "$OUTPUT"
    echo "$commits" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    has_commits=true
  fi
done

if [ "$has_commits" = false ]; then
  echo "이번 주에는 커밋이 없습니다." >> "$OUTPUT"
  echo "NO_COMMITS" > "$PROJECT_DIR/.auto-post-status"
else
  echo "HAS_COMMITS" > "$PROJECT_DIR/.auto-post-status"
fi

echo "커밋 수집 완료: $OUTPUT"
