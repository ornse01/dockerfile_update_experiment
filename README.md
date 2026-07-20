# Dockerfile 自動更新＆脆弱性スキャン実験プロジェクト

本プロジェクトは、GitHub Actions を用いて Dockerfile のベースイメージ自動更新、定期的なセキュリティスキャン（Trivy）、静的解析（zizmor）、および継続的インテグレーション（CI/CD）の実験を行うためのリポジトリです。

すべてのサードパーティ製 GitHub Actions アクションは、サプライチェーン攻撃対策としてコミット SHA ハッシュによってバージョンが固定され、Dependabot によって安全に自動更新（7日間のクールダウン期間付き）される設計となっています。

## ディレクトリ構成

```text
.
├── .github/
│   ├── dependabot.yml          # Dependabot自動更新設定 (クールダウン 7日)
│   └── workflows/
│       ├── update-dockerfiles.yml    # 定期ベースイメージ更新 & PR作成
│       ├── test-dockerfiles.yml      # PR時のビルドテスト & 脆弱性スキャン (Trivy)
│       ├── publish-stable-image.yml  # mainマージ時のビルド & GHCRプッシュ
│       ├── trivy-scan.yml            # 定期的なGHCRイメージスキャン & 脆弱性検知時PR作成
│       └── zizmor.yml                # ワークフローファイルの静的セキュリティ解析 (zizmor)
├── scripts/
│   ├── update-dockerfiles.rb   # Docker Hub APIからダイジェストを取得しDockerfileとCHANGELOGを更新するスクリプト
│   └── run-dummy-tests.sh      # コンテナ内で実行される検証用ダミーテストスクリプト
├── stable/
│   └── Dockerfile              # Debian stable ベースのテスト用Dockerfile
├── unstable/
│   └── Dockerfile              # Debian unstable ベースのテスト用Dockerfile
├── CHANGELOG.md                # スクリプトで自動追記される更新履歴ファイル
├── LICENSE                     # CC0 1.0 Universal ライセンスファイル
└── .gitignore                  # Trivyのデータベースキャッシュ (.cache/) を除外
```

---

## 開発フローと仕組み

### 1. ベースイメージの自動更新 & PR作成
*   **動作**: `update-dockerfiles.yml` ワークフローが毎週定期的に実行されます。
*   **処理内容**:
    1.  [scripts/update-dockerfiles.rb](scripts/update-dockerfiles.rb) が起動し、Docker Hub API から `debian:stable-slim` および `debian:unstable-slim` の最新の `sha256` ダイジェストを取得します。
    2.  各 Dockerfile 内の `FROM` 指示子のダイジェスト（例: `@sha256:...`）を最新に書き換えます。
    3.  差分が発生した場合、[CHANGELOG.md](CHANGELOG.md) に更新履歴を自動追記します。
    4.  更新結果を含むプルリクエスト (PR) を自動で作成します。

### 2. プルリクエスト時のCI（ビルド＆テスト）
*   **動作**: Dockerfile が変更された PR が作成されると、`test-dockerfiles.yml` が自動起動します。
*   **処理内容**:
    1.  変更のあった Dockerfile から Docker イメージをビルドします（GitHub Actions の `gha` キャッシュを用いてビルド時間を短縮します）。
    2.  ビルド直後、Trivy を用いてイメージの脆弱性スキャンを行います。PRのテストがブロックされるのを防ぐため、**修正可能な `CRITICAL, HIGH` 脆弱性のみ**を検知してビルドをエラーにします。
    3.  構築されたコンテナ内で [scripts/run-dummy-tests.sh](scripts/run-dummy-tests.sh) が実行され、テストを行います（デフォルトではコンテナ内の `curl` の有無を確認するダミーテストです）。

#### テスト成功・失敗のテスト方法
*   **失敗の検証**: `scripts/run-dummy-tests.sh` の末尾にある `exit 0` を `exit 1` に書き換えてプッシュすると、GitHub Actions のテストジョブを意図的に失敗させることができます。

### 3. mainマージ時の自動デプロイ (GHCRプッシュ & 署名)
*   **動作**: PR が `main` ブランチにマージされ、かつ `stable/Dockerfile` に変更があった場合に `publish-stable-image.yml` が動作します。
*   **処理内容**:
    1.  GHA のビルドキャッシュを引き継ぎ、イメージをビルドします。
    2.  GitHub Container Registry (GHCR) に、実行日の年月日（`YYYYMMDD`）タグおよび `latest` タグを付与し、さらに Provenance と SBOM のアテステーション情報を添付して自動プッシュします。
    3.  プッシュした Docker イメージに対し、`sigstore/cosign` を使用して署名を行います（Keyless 署名）。これにより、改ざん防止と信頼性の検証が可能になります。

### 4. 定期脆弱性スキャン (Trivyによるチェックと更新)
*   **動作**: `trivy-scan.yml` ワークフローが毎日深夜に実行されます。
*   **処理内容**:
    1.  GHCR にある `latest` イメージに対して Trivy スキャンを実行し、未修正の脆弱性（`ignore-unfixed: false`）を含む全重大度の結果を **Job Summary (ジョブ要約)** に出力して記録を残します。
    2.  一方、ワークフローの成否を判定するステップでは `ignore-unfixed: true` を指定してスキャンを行います。これにより、対策手段がない未修正の脆弱性だけでビルドが失敗（赤ステータスや不要なアラート通知）するのを抑制します。
    3.  修正可能な脆弱性が検出された（ビルドが失敗した）場合のみ、自動で更新スクリプトを走らせてベースイメージを最新のダイジェストに更新し、CHANGELOG に記録を追記して、自動更新の PR を作成します。

### 5. ワークフローファイルのセキュリティ静的解析
*   **動作**: ワークフローファイルが変更された場合、または手動起動で `zizmor.yml` が動作します。
*   **処理内容**:
    1.  `zizmor-action` (zizmor) を使用して、リポジトリ内の GitHub Actions ワークフロー設定におけるセキュリティ上の問題（過剰な権限、未ピン留めのアクション参照など）をスキャン・報告します。

---

## 署名の検証

本プロジェクトでビルドされ GHCR にプッシュされた Docker イメージは、`sigstore/cosign` による Keyless 署名が施されています。
署名を検証することで、対象のイメージが本リポジトリの特定のワークフロー（`main` ブランチ）からビルド・プッシュされた真正なものであることを確認できます。

### 検証コマンド

以下の `cosign verify` コマンドを実行することで、イメージの署名と証明書の検証を行うことができます。

```bash
cosign verify ghcr.io/ornse01/debian-stable:[タグ名] \
  --certificate-identity-regexp "^https://github\.com/ornse01/dockerfile_update_experiment/\.github/workflows/.+@refs/heads/main$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

*   `[タグ名]` には、検証したいイメージのタグ（例: `latest` や `20260712` などの日付タグ）を指定してください。
*   `--certificate-identity-regexp` オプションで、署名を実行した GitHub Actions ワークフローのアイデンティティ（本リポジトリの `main` ブランチ上のワークフロー）を確認します。
*   `--certificate-oidc-issuer` オプションで、証明書の OIDC イシュアーが GitHub Actions（`https://token.actions.githubusercontent.com`）であることを確認します。

---

## アテステーション（SBOM・Provenance）の検証

本プロジェクトでビルドされ GHCR にプッシュされた Docker イメージには、ソフトウェアサプライチェーンの透明性と安全性を高めるため、ビルド来歴情報（Provenance）およびソフトウェア部品構成表（SBOM）のアテステーション情報が添付されています。

### 検証コマンド

以下の `docker buildx imagetools inspect` コマンドを実行することで、提供されている Provenance および SBOM の JSON データを取得・確認できます。

**Provenance（ビルド来歴情報）の確認:**
```bash
docker buildx imagetools inspect ghcr.io/ornse01/debian-stable:[タグ名] --format "{{ json .Provenance }}"
```

**SBOM（ソフトウェア部品構成表）の確認:**
```bash
docker buildx imagetools inspect ghcr.io/ornse01/debian-stable:[タグ名] --format "{{ json .SBOM }}"
```

---

## ライセンス

本プロジェクトは [CC0 1.0 Universal](LICENSE) (Public Domain Dedication) に基づいてライセンスされています。商用・非商用問わず、誰でも自由に変更、再利用、配布が可能です。
