#!/bin/bash
# bit 자동 블로그 글쓰기 파이프라인
# cron 진입점: 커밋 수집 → Claude로 글 생성 → 빌드 → push
set -euo pipefail

# cron 환경에서 gh, claude, uv, git 등을 찾을 수 있도록 PATH 설정
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== bit 자동 포스트 시작: $(date) ==="

# 1. 최신 상태 동기화
echo "[1/5] git pull..."
git pull --rebase origin main

# 2. 커밋 수집
echo "[2/5] 커밋 수집..."
bash "$SCRIPT_DIR/collect-commits.sh"

# 커밋이 없으면 종료
if [ -f "$PROJECT_DIR/.auto-post-status" ] && [ "$(cat "$PROJECT_DIR/.auto-post-status")" = "NO_COMMITS" ]; then
  echo "이번 주 커밋이 없어서 글을 생성하지 않습니다."
  rm -f "$PROJECT_DIR/.auto-post-status" "$PROJECT_DIR/commits.md"
  exit 0
fi

# 3. Claude로 블로그 글 생성
echo "[3/5] Claude로 글 생성..."
claude -p "$(cat "$SCRIPT_DIR/generate-post-prompt.md")" --allowedTools "Write,Edit,Bash(mkdir)"

# 4. 빌드
echo "[4/5] 사이트 빌드..."
make build

# 5. 커밋 & push
echo "[5/5] 커밋 & push..."
DATE_YYMMDD=$(date +%y%m%d)
git add contents/ docs/
git commit -m "✨ feat: 주간 빌드인퍼블릭 자동 포스트 ($DATE_YYMMDD)" || {
  echo "변경사항 없음, 스킵"
  exit 0
}
git push origin main

# 정리
rm -f "$PROJECT_DIR/.auto-post-status" "$PROJECT_DIR/commits.md"

echo "=== 완료: $(date) ==="
