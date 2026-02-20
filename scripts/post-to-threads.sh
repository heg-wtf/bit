#!/bin/bash
# Threads 자동 포스팅 스크립트
# 블로그 글의 요약과 링크를 Threads에 발행
# 모든 실패는 exit 0 — 블로그 파이프라인을 절대 막지 않음
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# .env 로드
if [ ! -f "$ENV_FILE" ]; then
  echo "[Threads] .env 파일 없음, 스킵"
  exit 0
fi
source "$ENV_FILE"

# 환경변수 확인
if [ -z "${THREADS_ACCESS_TOKEN:-}" ] || [ -z "${THREADS_USER_ID:-}" ]; then
  echo "[Threads] THREADS_ACCESS_TOKEN 또는 THREADS_USER_ID 미설정, 스킵"
  exit 0
fi

# 날짜 처리 (인자 또는 오늘 날짜)
DATE_YYMMDD="${1:-$(date +%y%m%d)}"
YEAR="20${DATE_YYMMDD:0:2}"
MONTH="${DATE_YYMMDD:2:2}"
DAY="${DATE_YYMMDD:4:2}"

BLOG_URL="https://bit.heg.wtf/${YEAR}/${MONTH}/${DAY}/${DATE_YYMMDD}/"
CONTENT_FILE="$PROJECT_DIR/contents/${DATE_YYMMDD}/${DATE_YYMMDD}.md"

if [ ! -f "$CONTENT_FILE" ]; then
  echo "[Threads] 콘텐츠 파일 없음: $CONTENT_FILE, 스킵"
  exit 0
fi

# frontmatter 제거 후 첫 단락 추출 (200자 제한)
extract_summary() {
  local file="$1"
  local in_frontmatter=false
  local frontmatter_ended=false
  local paragraph=""

  while IFS= read -r line; do
    if [ "$frontmatter_ended" = false ]; then
      if [ "$line" = "---" ]; then
        if [ "$in_frontmatter" = true ]; then
          frontmatter_ended=true
        else
          in_frontmatter=true
        fi
        continue
      fi
      continue
    fi

    # frontmatter 이후 빈 줄 스킵
    if [ -z "$line" ] && [ -z "$paragraph" ]; then
      continue
    fi

    # 빈 줄 만나면 첫 단락 끝
    if [ -z "$line" ] && [ -n "$paragraph" ]; then
      break
    fi

    # 헤딩(##)은 스킵
    if [[ "$line" =~ ^## ]]; then
      if [ -n "$paragraph" ]; then
        break
      fi
      continue
    fi

    paragraph="$paragraph$line"
  done < "$file"

  # 200자 제한
  if [ ${#paragraph} -gt 200 ]; then
    paragraph="${paragraph:0:197}..."
  fi

  echo "$paragraph"
}

SUMMARY=$(extract_summary "$CONTENT_FILE")

if [ -z "$SUMMARY" ]; then
  echo "[Threads] 요약 추출 실패, 스킵"
  exit 0
fi

POST_TEXT="${SUMMARY}

${BLOG_URL}"

echo "[Threads] 포스트 내용:"
echo "$POST_TEXT"
echo ""

# 토큰 갱신 시도
refresh_token() {
  echo "[Threads] 토큰 갱신 시도..."
  local response
  response=$(curl -s "https://graph.threads.net/refresh_access_token?grant_type=th_refresh_token&access_token=${THREADS_ACCESS_TOKEN}")

  local new_token
  new_token=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

  if [ -n "$new_token" ] && [ "$new_token" != "$THREADS_ACCESS_TOKEN" ]; then
    echo "[Threads] 토큰 갱신 성공"
    # .env 파일 업데이트
    sed -i '' "s|THREADS_ACCESS_TOKEN=.*|THREADS_ACCESS_TOKEN=${new_token}|" "$ENV_FILE"
    THREADS_ACCESS_TOKEN="$new_token"
  else
    echo "[Threads] 토큰 갱신 불필요 또는 실패 (기존 토큰 사용)"
  fi
}

refresh_token

# 1단계: 컨테이너 생성
echo "[Threads] 컨테이너 생성..."
CONTAINER_RESPONSE=$(curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads" \
  -d "media_type=TEXT" \
  --data-urlencode "text=${POST_TEXT}" \
  -d "access_token=${THREADS_ACCESS_TOKEN}")

CONTAINER_ID=$(echo "$CONTAINER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

if [ -z "$CONTAINER_ID" ]; then
  echo "[Threads] 컨테이너 생성 실패: $CONTAINER_RESPONSE"
  exit 0
fi

echo "[Threads] 컨테이너 ID: $CONTAINER_ID"

# 2단계: 발행 대기
echo "[Threads] 30초 대기..."
sleep 30

# 3단계: 발행
echo "[Threads] 발행 중..."
PUBLISH_RESPONSE=$(curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish" \
  -d "creation_id=${CONTAINER_ID}" \
  -d "access_token=${THREADS_ACCESS_TOKEN}")

PUBLISH_ID=$(echo "$PUBLISH_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

if [ -z "$PUBLISH_ID" ]; then
  echo "[Threads] 발행 실패: $PUBLISH_RESPONSE"
  exit 0
fi

echo "[Threads] 발행 완료! Post ID: $PUBLISH_ID"
