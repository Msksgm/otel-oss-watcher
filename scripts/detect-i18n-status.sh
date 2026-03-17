#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/reports"
WORK_DIR=$(mktemp -d)

trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== opentelemetry.io 日本語翻訳状況の検出 ==="

# opentelemetry.io リポジトリをクローン
echo "Cloning opentelemetry.io..."
git clone --depth 1 https://github.com/open-telemetry/opentelemetry.io.git "$WORK_DIR/opentelemetry.io"
cd "$WORK_DIR/opentelemetry.io"

# git の全履歴が必要（default_lang_commit との diff に使用）
echo "Fetching full git history..."
git fetch --unshallow

# npm install
echo "Installing dependencies..."
npm install --ignore-scripts

# --- 1. 未翻訳ページの検出 ---
echo ""
echo "=== 未翻訳ページの検出 ==="

UNTRANSLATED_FILE="$REPORTS_DIR/untranslated-pages.txt"
mkdir -p "$REPORTS_DIR"

# content/en の .md ファイルを列挙し、content/ja に対応ファイルがないものを抽出
: > "$UNTRANSLATED_FILE"
find content/en -name '*.md' -type f -not -path '*/blog/*' | sort | while read -r en_file; do
  ja_file="${en_file/content\/en/content\/ja}"
  if [ ! -f "$ja_file" ]; then
    echo "$en_file" >> "$UNTRANSLATED_FILE"
  fi
done

UNTRANSLATED_COUNT=$(wc -l < "$UNTRANSLATED_FILE" | tr -d ' ')
echo "未翻訳ページ: ${UNTRANSLATED_COUNT} 件"
echo "出力: $UNTRANSLATED_FILE"

# --- 2. drifted ページの検出 ---
echo ""
echo "=== drifted ページの検出 ==="

DRIFTED_FILE="$REPORTS_DIR/drifted-pages.txt"

# npm run check:i18n -- content/ja の出力から drifted ファイルを抽出
# 出力形式: "> Drifted file: content/ja/docs/foo.md"
npm run check:i18n -- content/ja 2>&1 | grep '^> Drifted file: ' | sed 's/^> Drifted file: //' | sort > "$DRIFTED_FILE"

DRIFTED_COUNT=$(wc -l < "$DRIFTED_FILE" | tr -d ' ')
echo "drifted ページ: ${DRIFTED_COUNT} 件"
echo "出力: $DRIFTED_FILE"

echo ""
echo "=== 完了 ==="
