---
status: accepted
date: 2026-10-08
decision-makers: ornse01, Antigravity
---

# Trivy スキャン結果の出力先を GitHub Security（SARIF）に変更

## 背景と問題の本質 (Context and Problem Statement)

日次の脆弱性スキャンワークフロー (`trivy-scan.yml`) において、検出された全脆弱性のテキストレポートを `$GITHUB_STEP_SUMMARY`（Job Summary）へ出力していました。
しかし、スキャン対象イメージ（Debian stable）の脆弱性情報量が増加した結果、レポートサイズが約 1.39 MB（1391 KB）に達しました。
GitHub Actions の `$GITHUB_STEP_SUMMARY` には 1024 KB（1 MB）のサイズ上限があるため、以下のエラーが発生してサマリーのアップロードが中断され、結果を確認できない状態となっていました。

> Error: $GITHUB_STEP_SUMMARY upload aborted, supports content up to a size of 1024k, got 1391k.

脆弱性スキャンの結果を確実に記録・閲覧できるようにするため、出力先および出力方式を見直す必要が生じました。

## 決定要因 (Decision Drivers)

* **サイズ上限の回避**: 1024 KB の Job Summary 上限に抵触せず、確実に結果が保存・閲覧できること。
* **脆弱性の管理・視認性**: 多数の検出結果の中から重要な脆弱性を容易に把握・トリアージできること。
* **運用の統一性**: 他のセキュリティスキャン（zizmor 等）と同様に、GitHub ネイティブのセキュリティ管理機能と統合できること。

## 検討した選択肢 (Considered Options)

* **選択肢1: GitHub Actions の Artifacts（成果物）としてアップロード** (`actions/upload-artifact`)
* **選択肢2: GitHub Security タブ (Code Scanning / SARIF) への連携** (`github/codeql-action/upload-sarif`)
* **選択肢3: ワークフロー実行ログ（標準出力 / コンソール）への出力**
* **選択肢4: Job Summary の出力対象を絞り込む（フィルタリング）**

## 意思決定の結末 (Decision Outcome)

選択されたオプション: **選択肢2: GitHub Security タブ (Code Scanning / SARIF) への連携**

理由:
GitHub Code Scanning と連携することで、1024 KB のサマリー上限を回避できるだけでなく、GitHub の「Security」タブ上で各脆弱性の重大度、修正可否、詳細情報を個別に一覧・トリアージ・管理できるようになり、運用の利便性が大幅に向上するため。また、既存の `zizmor.yml` でも `security-events: write` が利用されており、リポジトリの設定や運用方針とも親和性が高い。

### 変更点

1. **ワークフロー権限の追加**:
   - `permissions` に `security-events: write` を追加。
2. **Trivy の出力フォーマット変更**:
   - `format: 'table'` から `format: 'sarif'` に変更。
   - `output: 'trivy-results.sarif'` に設定。
3. **SARIF アップロードステップの追加**:
   - `github/codeql-action/upload-sarif` を使用して SARIF レポートをアップロード。
   - 以前の `$GITHUB_STEP_SUMMARY` への `cat` 出力ステップを削除。

## 影響・結果 (Consequences)

* 良い点:
  * `$GITHUB_STEP_SUMMARY` のサイズ制限エラーが解消された。
  * GitHub Security タブの Code scanning alerts として、脆弱性の状態管理（オープン、解決済み、誤検知等のトリアージ）が可能になった。
* 悪い点 / 注意点:
  * ジョブのサマリ画面でインラインにプレビューされるのではなく、「Security」タブ（またはジョブ画面のリンク）を開いて確認する動線となる。

## 各選択肢のメリットとデメリット (Pros and Cons of the Options)

### 選択肢1: GitHub Actions の Artifacts（成果物）としてアップロード

* 良い点: サイズ制限が大きく、1 MB 超のテキストやHTMLレポートを確実に保存できる。
* 悪い点: 確認するたびに zip ファイルをダウンロード・展開して閲覧する手間がある。

### 選択肢2: GitHub Security タブ (Code Scanning / SARIF) への連携（採用）

* 良い点: GitHub ネイティブの UI で視認性・検索性・トリアージ機能が利用できる。
* 良い点: 1024 KB 上限のエラーを根本的に解決できる。
* 悪い点: `security-events: write` 権限が必要（本リポジトリではすでに利用可能）。

### 選択肢3: ワークフロー実行ログ（標準出力 / コンソール）への出力

* 良い点: 追加のアクションや保存ストレージが不要。
* 悪い点: ログが膨大（数千〜数万行）になり、ブラウザのログビューアでの閲覧や検索が困難。

### 選択肢4: Job Summary の出力対象を絞り込む（フィルタリング）

* 良い点: 引き続き Job Summary で確認可能。
* 悪い点: 未修正の脆弱性や低重大度の脆弱性が確認できなくなり、全体像の把握が難しくなる。

## 関連情報 (More Information)

* [ADR-0005: ベースイメージ更新と脆弱性対応再ビルドの責務分離](0005-separate-base-image-update-and-vulnerability-rebuild.md)
* [GitHub ドキュメント: SARIF ファイルを GitHub にアップロードする](https://docs.github.com/ja/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github)
