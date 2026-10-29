---
status: accepted
date: 2026-10-29
decision-makers: ornse01, Antigravity
---

# 自動更新 PR の自動マージ導入と Gatekeeper パターンによる必須チェックデッドロックの回避

## 背景と問題の本質 (Context and Problem Statement)

ベースイメージ更新ワークフロー (`update-dockerfiles.yml`) および Trivy 脆弱性更新ワークフロー (`trivy-scan.yml`) により、Dockerfile の更新 PR が定期的に自動作成されています。
これまでは人間が手動で CI（`test-dockerfiles.yml`）の通過を確認した上でマージを行っていましたが、定期更新作業の自動化・効率化のため、テストが通過した場合は自動的にマージ（Merge commit）を行いたいという要望がありました。

GitHub のネイティブ機能である Auto-merge を利用する場合、対象ブランチ（`main`）の保護ルールでテスト結果を必須ステータスチェック（Required status check）に指定する必要があります。
しかし、既存の `test-dockerfiles.yml` には `paths: ['**/Dockerfile']` フィルタが設定されており、Dockerfile を変更しない PR（ドキュメント修正など）ではワークフロー自体が起動せず、必須チェックが Expected / Pending のまま残りマージ不能（デッドロック）になる問題が発生します。

そのため、安全な自動マージ機構と、必須チェックのデッドロックを防止する仕組みを併せて設計・導入する必要が生じました。

## 決定要因 (Decision Drivers)

* **運用効率化**: 自動作成される PR のテスト通過確認およびマージ作業を自動化すること。
* **マージブロッカー（デッドロック）の防止**: Dockerfile を含まない他の PR が必須チェックによってマージ不能にならないこと。
* **リソース効率**: Dockerfile 変更がない PR で重い Docker ビルドやスキャンを実行しないこと。
* **標準性と堅牢性**: ポーリングや独自スクリプトの待機ループに依存せず、GitHub ネイティブの Auto-merge 機能を活用すること。

## 検討した選択肢 (Considered Options)

* **選択肢1: GitHub ネイティブ Auto-merge ＋ Gatekeeper パターン（dorny/paths-filter ＋ 集約判定ジョブ）**
* **選択肢2: GitHub 公式推奨のパス逆パターンによるダミーワークフローを用意**
* **選択肢3: ブランチ保護ルールを使わず、テストジョブ末尾で直接 `gh pr merge` を実行**

## 意思決定の結末 (Decision Outcome)

選択されたオプション: **選択肢1: GitHub ネイティブ Auto-merge ＋ Gatekeeper パターン**

理由:
- `gh pr merge --auto --merge` により、PR 作成と同時に自動マージを予約でき、CI の完了をポーリング待機する必要がないため。
- `dorny/paths-filter` で変更パスを検知し、Dockerfile が変更された場合のみテストジョブを実行することで CI リソースを節約できるため。
- 集約判定ジョブ (`gatekeeper`) をブランチ保護ルールの必須チェックに指定することで、Dockerfile 変更のない PR でも即座にチェックが Green となり、デッドロックが確実に回避できるため。

### 変更点

1. **`test-dockerfiles.yml`**:
   - `on.pull_request` から `paths` フィルタを削除し、PR 作成時に常に起動。
   - `check-changes` ジョブを追加し、`dorny/paths-filter` で `**/Dockerfile` の変更有無を判定。
   - `build-and-test` ジョブに `needs: check-changes` および `if: needs.check-changes.outputs.dockerfile == 'true'` を付与。
   - `gatekeeper` ジョブを追加。テストが成功、または Dockerfile 変更なしでスキップされた場合に正常終了 (`exit 0`) と判定。このジョブをブランチ保護の必須チェック対象とする。
2. **`update-dockerfiles.yml`**:
   - PR 作成ステップに `id: cpr` を付与。
   - PR が作成・更新された場合、GitHub App トークンを用いて `gh pr merge "$PR_NUMBER" --auto --merge` を実行するステップを追加。
3. **`trivy-scan.yml`**:
   - 同様に PR 作成ステップに `id: cpr` を付与し、`gh pr merge "$PR_NUMBER" --auto --merge` を実行するステップを追加。

## 影響・結果 (Consequences)

### 肯定的な結果 (Positive Consequences)
* ベースイメージ更新および Trivy セキュリティ更新の PR が、テスト通過後に人手を介さず自動的に Merge commit でマージされるようになる。
* ドキュメントや他ファイルの PR 作成時にもデッドロックが発生せず、スムーズにマージできる。
* ジョブ単位で permissions を最小化し、環境変数を介して PR 番号を渡すことで、zizmor によるセキュリティ監査もパスする安全な構成となる。

### 否定的な結果・考慮点 (Negative Consequences)
* GitHub リポジトリ設定側で「Allow auto-merge」を有効化し、`main` ブランチの保護ルールで `gatekeeper`（Gatekeeper）を必須チェックに設定する必要がある。

## 関連情報 (More Information)

* GitHub 公式: [Handling skipped PR checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/troubleshooting-required-status-checks#handling-skipped-pr-checks)
* [dorny/paths-filter](https://github.com/dorny/paths-filter)
