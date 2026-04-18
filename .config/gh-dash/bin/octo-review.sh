#!/usr/bin/env bash
# gh dash の "Checkout & Review" 用ラッパー。
# - PR をチェックアウト
# - 既存の pending レビューがあれば :Octo review resume、無ければ :Octo review start
set -uo pipefail

REPO="${1:?repo (owner/name) required}"
PR="${2:?pr number required}"

if ! gh pr checkout "$PR"; then
  echo "❌ gh pr checkout $PR に失敗しました（未コミット変更などが原因の可能性）"
  read -r -p "Enter で閉じる..."
  exit 1
fi

ME=$(gh api user --jq .login 2>/dev/null || echo "")
PENDING=""
if [ -n "$ME" ]; then
  PENDING=$(gh api "repos/$REPO/pulls/$PR/reviews" \
    --jq ".[] | select(.user.login==\"$ME\" and .state==\"PENDING\") | .id" \
    2>/dev/null | head -n1)
fi

if [ -n "$PENDING" ]; then
  echo "↻ 既存の pending レビュー (#$PENDING) を再開します"
  exec nvim "+Octo review resume"
else
  exec nvim "+Octo review start"
fi
