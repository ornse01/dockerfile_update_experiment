#!/usr/bin/env bash
set -e

echo "=== Running Dummy Tests inside Container ==="

# コンテナ内に curl がインストールされているかチェックする
if ! command -v curl &> /dev/null; then
    echo "FAIL: curl is not installed!"
    exit 1
fi
echo "PASS: curl is installed (version: $(curl --version | head -n 1))"

# 成功・失敗の動きをGitHub上で確認するためのダミー終了コード
# 失敗させたい場合は、以下を「exit 1」に書き換えてコミット・プッシュしてください。
exit 0
