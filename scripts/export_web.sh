#!/usr/bin/env bash
# Godot 4 → HTML5ビルド → Vercelデプロイ用スクリプト
set -euo pipefail

GODOT="${GODOT_BIN:-godot4}"
PROJECT_DIR="$(cd "$(dirname "$0")/../client" && pwd)"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/build/web"

echo "[1/3] Webエクスポート中..."
mkdir -p "$BUILD_DIR"
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Web (Vercel)" "$BUILD_DIR/index.html"

echo "[2/3] .htaccess / _headers をコピー..."
cat > "$BUILD_DIR/_headers" <<'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

echo "[3/3] ビルド完了: $BUILD_DIR"
echo "デプロイ: vercel --prod (リポジトリルートで実行)"
