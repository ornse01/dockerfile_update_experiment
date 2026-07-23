---
name: github-actions-version-updater
description: GitHub Actions の Action を追加する際に、cooldown.default-days を考慮して安全な最新バージョン（タグ）とそのコミットハッシュを取得し、指定するためのスキル。
---

# GitHub Actions の Action 追加時の最新バージョン指定手順

GitHub Actions の Action を追加する際、指定されたクールダウン期間（安全期間）を経過した最新バージョン (タグ) およびそのフルコミットハッシュを特定し、ワークフローに記述するための手順です。

## 手順 1. クールダウン期間（日数）の取得

プロジェクトの [dependabot.yml](../../../.github/dependabot.yml) ファイルから、`github-actions` パッケージエコシステムに設定されている `cooldown.default-days` の値を取得します。

- **ファイルパス**: `.github/dependabot.yml`
- **確認対象**:
  ```yaml
  updates:
    - package-ecosystem: "github-actions"
      ...
      cooldown:
        default-days: 7  # この値を取得します
  ```

※ 設定されていない場合、またはファイルが存在しない場合はデフォルトのポリシー（例: 0日 または 7日など）に従います。

## 手順 2. クールダウン期間を経過した最新のタグを取得

取得したクールダウン日数に基づき、リリース日からその日数分経過しているリリースのうち、最新のタグを取得します。

以下のコマンドの `[オーナー]`、`[リポジトリ]`、および `[日数]` を実際の値に置き換えて実行します。

```bash
curl -s https://api.github.com/repos/[オーナー]/[リポジトリ]/releases | jq -r '
  (now - ([日数] * 86400)) as $cutoff
  | [ .[] | select((.published_at | fromdateiso8601) <= $cutoff) ]
  | .[0].tag_name
'
```

### 実行例（actions/checkout の場合、クールダウン 7 日）
```bash
curl -s https://api.github.com/repos/actions/checkout/releases | jq -r '
  (now - (7 * 86400)) as $cutoff
  | [ .[] | select((.published_at | fromdateiso8601) <= $cutoff) ]
  | .[0].tag_name
'
```

## 手順 3. タグに対応するコミットハッシュを取得

セキュリティ上のベストプラクティスとして、Action の指定にはタグ名ではなく、改ざん防止のためにフルコミットハッシュを使用します。
手順 2 で取得したタグ名から、対応するコミットハッシュを取得します。

以下のコマンドの `[オーナー]`、`[リポジトリ]`、および `[タグ名]` を実際の値に置き換えて実行します。

```bash
curl -s https://api.github.com/repos/[オーナー]/[リポジトリ]/commits/[タグ名] | jq -r '.sha'
```

### 実行例（actions/checkout のタグ `v4.1.7` の場合）
```bash
curl -s https://api.github.com/repos/actions/checkout/commits/v4.1.7 | jq -r '.sha'
```

## 手順 4. ワークフローへの記述

取得したコミットハッシュとタグ名をコメントの形でワークフローファイルに記述します。

```yaml
- name: Checkout repository
  uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4.1.7
```
