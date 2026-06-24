#!/usr/bin/env bash
set -euo pipefail

# 対象の Dockerfile と対応するベースイメージ、タグの定義
# 書式: "Dockerfileのパス:ベースイメージ名:タグ"
TARGETS=(
  "stable/Dockerfile:debian:stable-slim"
  "unstable/Dockerfile:debian:unstable-slim"
)

# 最新のダイジェストを取得する関数
get_latest_digest() {
  local image="$1"
  local tag="$2"
  
  # Docker Hubの認証トークンを取得 (匿名)
  local token
  token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/${image}:pull" | jq -r '.token')
  
  if [ -z "$token" ] || [ "$token" = "null" ]; then
    echo "Error: Failed to get token for ${image}" >&2
    return 1
  fi
  
  # Manifest List を優先的に要求し、レスポンスヘッダからダイジェストを取得する
  local digest
  digest=$(curl -sI \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json" \
    "https://registry-1.docker.io/v2/library/${image}/manifests/${tag}" \
    | grep -i "docker-content-digest" \
    | awk '{print $2}' \
    | tr -d '\r\n')
    
  echo "$digest"
}

# 各ターゲットをループ処理して更新
for target in "${TARGETS[@]}"; do
  IFS=":" read -r df_path img tag <<< "$target"
  
  echo "Checking ${df_path} (${img}:${tag})..."
  
  if [ ! -f "$df_path" ]; then
    echo "Warning: File ${df_path} does not exist. Skipping."
    continue
  fi
  
  latest_digest=$(get_latest_digest "$img" "$tag")
  if [ -z "$latest_digest" ]; then
    echo "Error: Could not retrieve digest for ${img}:${tag}" >&2
    exit 1
  fi
  
  echo "Latest digest: ${latest_digest}"
  
  # FROM 行を最新のダイジェスト付きに書き換え
  # 「FROM debian:stable-slim」 または 「FROM debian:stable-slim@sha256:xxxx」 を置換する
  export img tag latest_digest
  perl -pi -e 's|FROM\s+$ENV{img}:$ENV{tag}(\@sha256:[a-f0-9]{64})?|FROM $ENV{img}:$ENV{tag}\@$ENV{latest_digest}|g' "${df_path}"
  
  echo "Updated ${df_path} successfully."
  echo "----------------------------------------"
done
