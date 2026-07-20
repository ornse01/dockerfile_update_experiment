---
status: proposed
date: 2026-07-20
decision-makers: ornse01, Antigravity
---

# GitHub ActionでGitHub Appsトークンを使用する

## 背景と問題の本質 (Context and Problem Statement)

現在、本リポジトリではベースイメージの自動更新 (`update-dockerfiles.yml`) や定期脆弱性スキャン (`trivy-scan.yml`) のワークフローにおいて、プルリクエスト (PR) の自動作成に `peter-evans/create-pull-request` を使用しており、トークンとしてデフォルトの `${{ secrets.GITHUB_TOKEN }}` を渡しています。

しかし、GitHub Actions の仕様により、`GITHUB_TOKEN` を使用して作成または更新されたリソース（PRなど）は、他の GitHub Actions ワークフロー（例: `test-dockerfiles.yml`）をトリガーしません。これにより、自動作成されたPRに対してCI（ビルドテストや検証）が自動実行されず、人間が手動でトリガーするか、空コミットをプッシュするなどの手間が発生しており、完全な自動化の妨げとなっています。

また、将来的に特定のPR作成者が特定の自動化ツール（GitHub App）であることを条件に、GitHub Actionsの処理を条件分岐（例：自動作成されたPRのみ特定のテストをスキップする、あるいは自動マージの対象とするなど）したいという要望があります。

## 決定要因 (Decision Drivers)

* **CIの自動実行**: PR作成と同時に自動検証（ビルド、テスト、脆弱性スキャン）を自律的に開始させたい。
* **セキュリティと最小権限**: トークンの権限を必要最小限（コンテンツ書き込み、PR書き込みなど）に制限し、短寿命なトークンを利用したい。
* **運用の継続性**: 特定の個人アカウントの認証情報に依存せず、メンバーの変更などによる影響を受けないようにしたい。
* **アクターの識別性**: 将来的にPRの作成者が特定のシステム/AppであることをGitHub Actionsの条件分岐などで容易に判定できるようにしたい。

## 検討した選択肢 (Considered Options)

* **Option 1: GitHub Apps トークンを使用する (Use GitHub Apps Token)**
* **Option 2: Personal Access Token (PAT) を使用する (Use Personal Access Token)**
* **Option 3: ワークフロー側で `pull_request_target` イベントを使用する (Use `pull_request_target` event)**

## 意思決定の結末 (Decision Outcome)

選択されたオプション: **Option 1: GitHub Apps トークンを使用する (Use GitHub Apps Token)**

理由: 安全で細粒度なアクセス制御（必要な権限のみに制限され、トークンは短寿命）が実現でき、かつ個人アカウントに依存しないためです。さらに、PRの作成者（アクター）がGitHub Appになるため、アクター情報を基にした条件分岐が容易になります。

### 影響・結果 (Consequences)

* **良い点**:
  * 自動作成されたPRでCI（`test-dockerfiles.yml`）が即座に自動実行されるようになり、マージまでの自動化サイクルが完成する。
  * 短寿命（最大1時間）のインストールアクセストークンが動的に生成されるため、トークン漏洩時のセキュリティリスクが極めて低い。
  * 個人アカウントのPATではないため、管理者の退職や権限変更によってCIが突然停止するリスクを排除できる。
  * 将来的にGitHub Actionsコンテキスト (`github.actor` など) を使用し、「PR作成者が特定のGitHub Appである場合」といった条件分岐が容易かつ安全に行える。
* **悪い点**:
  * GitHub Appを新規作成し、適切な権限（`contents: write`, `pull-requests: write`）を設定して本リポジトリにインストールする初期設定作業が必要。
  * GitHub Appの `App ID` と `Private Key` をリポジトリの Secret に登録・管理する必要がある。

### 確認方法 (Confirmation)

1. GitHub Appから生成したトークンを用いて自動更新PRが正しく作成されることを確認する。
2. 作成されたPRにおいて、`test-dockerfiles.yml` などのPRトリガーのワークフローが自動で起動し、正常に完了することを確認する。

## 各選択肢のメリットとデメリット (Pros and Cons of the Options)

### Option 1: GitHub Apps トークンを使用する (Use GitHub Apps Token)

GitHub Organization/User レベルで GitHub App を作成し、該当リポジトリにインストールします。GitHub Actions 内では `actions/create-github-app-token` アクション等を使用して動的にトークンを生成します。

* 良い点:
  * 権限をリポジトリ単位かつ細粒度（Read/Write）に制限可能。
  * 生成されるトークンは1時間で期限切れになるため安全。
  * アクター名が App 名になり、ユーザー名と明確に区別できるため、CIの条件分岐で判定しやすい。
  * 個人に紐付かない。
* 悪い点:
  * GitHub Appの作成と鍵ペアの管理という初期セットアップの手間がある。

### Option 2: Personal Access Token (PAT) を使用する (Use Personal Access Token)

特定のユーザー（あるいはマシンユーザー）のPATを生成し、リポジトリの Secret（例: `PERSONAL_ACCESS_TOKEN`）に登録して使用します。

* 良い点:
  * セットアップが最も簡単（トークンを発行してSecretに登録するだけ）。
* 悪い点:
  * トークンの権限スコープがアカウント全体に及びやすく、漏洩時のリスクが高い。
  * トークンの有効期限管理が必要（期限切れによる突然のCI停止）。
  * 紐付いているユーザーがOrganizationから脱退した際や、パスワード変更等でトークンが無効化されると、自動更新処理が壊れる。
  * マシンユーザー用のアカウントを用意する場合、追加のライセンスコストやアカウント管理の手間が発生する。

### Option 3: ワークフロー側で `pull_request_target` イベントを使用する (Use `pull_request_target` event)

PR作成側のトークンは `GITHUB_TOKEN` のままとし、CI（`test-dockerfiles.yml`）のトリガーを `pull_request` から `pull_request_target` に変更します。これにより、`GITHUB_TOKEN` で作成されたPRであっても、ベースブランチのコンテキストでCIがトリガーされるようになります。

* 良い点:
  * 新たなトークンやGitHub Appの設定が一切不要。
* 悪い点:
  * `pull_request_target` は、PR側の悪意あるコード変更によってリポジトリの書き込み権限やSecretが盗み出されるセキュリティ上の脆弱性（Pwn requestなど）を生み出しやすく、コンテナビルドやテストの実行には推奨されない。
  * PR作成者を条件分岐に使う場合の根本的な解決にならない。

## 関連情報 (More Information)

* GitHub 公式ドキュメント: [GitHub Actionsのセキュリティ強化 - ワークフローから他のワークフローをトリガーする](https://docs.github.com/ja/actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow)
* アクション: [actions/create-github-app-token](https://github.com/actions/create-github-app-token)
