---
status: accepted
date: 2026-07-26
decision-makers: ornse01, Antigravity
---

# 0004: Trivyセキュリティ更新時のDockerレイヤーキャッシュ無効化（Cache Busting）

## 背景と問題の本質 (Context and Problem Statement)

本プロジェクトでは、定期的な Trivy スキャンによって GHCR 上のコンテナイメージに脆弱性が検知された場合、自動更新スクリプト（`scripts/update-dockerfiles.rb --trivy`）が起動してセキュリティ更新 PR を作成します。
しかし、上流のベースイメージ（例: `debian:stable-slim`）のダイジェスト値自体に変更がない場合、パッケージ更新（`apt-get upgrade`）のみを意図して Dockerfile を書き換える必要があります。

従来は `# SECURITY_UPDATE: YYYY-MM-DD` というコメント行を Dockerfile に挿入・更新していました。
しかし、Docker (BuildKit) のビルドキャッシュ機構においては、**コメント行の変更は `RUN` ステップのキャッシュキー計算から無視される**ため、以前の `RUN apt-get update && apt-get upgrade -y ...` のレイヤーキャッシュが再利用されてしまい、実際には `apt-get` によるパッケージ更新が実行されない問題が発生していました。

## 決定要因 (Decision Drivers)

* **脆弱性修正の確実性**: Trivy で検知された脆弱性に対するパッチ適用（`apt-get upgrade`）を確実にビルドレイヤーで再実行させる。
* **一貫性**: CI での PR 検証ビルド（`test-dockerfiles.yml`）および `main` ブランチマージ後のデプロイビルド（`publish-stable-image.yml`）の両方で同一の無効化メカニズムを機能させる。
* **履歴の明確性**: Git のコミット履歴および Dockerfile 自体でセキュリティ更新がいつ実行されたかを可視化する。

## 検討した選択肢 (Considered Options)

* **選択肢1: Dockerfile 内で `ARG SECURITY_UPDATE_DATE=YYYY-MM-DD` を使用して Cache Busting を行う**
* **選択肢2: GitHub Actions ワークフロー側で `no-cache: true` を指定する**
* **選択肢3: `RUN` 命令のテキスト自体を毎回変更する**

## 意思決定の結末 (Decision Outcome)

選択されたオプション: "**選択肢1: Dockerfile 内で `ARG SECURITY_UPDATE_DATE=YYYY-MM-DD` を使用して Cache Busting を行う**"

理由:
BuildKit の仕様上、`RUN` ステップより前に定義された `ARG` の値が変更されると、それ以降の `RUN` ステップのビルドキャッシュが自動的に破棄（Cache Busting）されます。ワークフロー側のトリガー条件やブランチ判定に依存せず、Dockerfile の変更自体によって確実にキャッシュ無効化と再ビルドが行われるため本手法を採用しました。

### 影響・結果 (Consequences)

* 良い点:
  * Trivy 検知時に `SECURITY_UPDATE_DATE` の日付が更新されることで、確実に `apt-get update && apt-get upgrade -y` が再実行される。
  * CI（PR検証）と CD（デプロイ）の両方でワークフロー設定を変更することなく動作する。
  * `ARG` の記述により、Dockerfile 内で最後のセキュリティ更新日が明確になる。
* 悪い点:
  * `ARG` 変数がビルド命令に含まれるため、Dockerfile の記述行が1行増える。

### 確認方法 (Confirmation)

* `scripts/update-dockerfiles.rb --trivy` を実行した際、Dockerfile 内の `ARG SECURITY_UPDATE_DATE=` の日付が更新されることを確認する。
* Docker ビルド時に `ARG` 以降の `RUN` ステップがキャッシュミスとなり、再実行されることを確認する。

## 各選択肢のメリットとデメリット (Pros and Cons of the Options)

### 選択肢1: Dockerfile 内で `ARG SECURITY_UPDATE_DATE=YYYY-MM-DD` を使用

* 良い点: BuildKit の標準的な Cache Busting 機構を活用でき、確実性が高い。
* 良い点: ワークフロー側の複雑なブランチ条件分岐やオプション指定が不要。
* 悪い点: Dockerfile 内にビルド変数（`ARG`）が追加される。

### 選択肢2: GitHub Actions ワークフロー側で `no-cache: true` を指定

* 良い点: Dockerfile の記述を変更する必要がない。
* 悪い点: `main` ブランチマージ後のデプロイ（`publish-stable-image.yml`）など、別イベントのワークフローで Trivy 由来の更新かどうかを判断するロジックが複雑化する。
* 悪い点: 全レイヤーのキャッシュが無効化されるため、依存関係等のビルド時間が無駄に長くなる可能性がある。

### 選択肢3: `RUN` 命令のテキスト自体を毎回変更する

* 良い点: キャッシュが無効化される。
* 悪い点: `RUN` 命令内に無駄な `echo` コマンド等を挿入することになり、Dockerfile の可読性と保守性が低下する。

## 関連情報 (More Information)

* PR #51 / Commit `9083bda`: `ARG SECURITY_UPDATE_DATE` 導入の変更コミット。
* [ADR-0001: ベースイメージの自動更新およびリリースフロー](0001-base-image-update-workflow.md)
