---
name: adr-management
description: Markdown Architectural Decision Records (MADR) 形式を使用して、アーキテクチャの意思決定記録 (ADR) を作成・管理します。新しいアーキテクチャの方向性の提案、主要なコンポーネントの導入、または技術設計の変更を行う際にこのスキルを使用します。
---

# ADR管理スキル (ADR Management Skill)

このスキルは、本リポジトリにおいて MADR (Markdown Architectural Decision Records) 標準に沿ってアーキテクチャ上の意思決定を記録するための手順をガイドします。

## このスキルをトリガーするタイミング
- 新しいツールやフレームワークの導入を提案するとき。
- 主要なアーキテクチャ上の設計や選択肢を決定するとき。
- 重要なワークフローやディレクトリ構造を変更するとき。
- 以前に記録されたアーキテクチャ決定を非推奨にしたり、新しい決定で置き換えるとき。

## ディレクトリ構成
すべてのADRは以下の場所に保存されます：
`docs/decisions/`

重要なファイル：
- [README.md](../../../docs/decisions/README.md) - ADRのメインインデックス（目次）。
- [adr-template.md](../../../docs/decisions/adr-template.md) - 新しいADRを作成する際にコピーする公式テンプレート。

## ファイル命名規則
ファイル名は以下のパターンに従う必要があります：
`docs/decisions/NNNN-kebab-case-title.md`
- `NNNN` は `0000` から始まる4桁の連番（例：`0001`, `0002`）。
- タイトル部分は、ADRのタイトルを小文字にし、スペースをハイフンに置き換えたケバブケース（kebab-case）にします。

## 新しいADRを作成する手順

1. **次の連番を確認する**: `docs/decisions/` ディレクトリの内容を確認し、現在の一番高いADRの番号を特定します。次の番号は `最大値 + 1` です。
2. **テンプレートをコピーする**: [adr-template.md](../../../docs/decisions/adr-template.md) の内容を、新しいファイルパス（例：`docs/decisions/0001-use-sqlite.md`）にコピーします。
3. **メタデータを記入する**:
   - `status`: 通常は `proposed`（提案中）から始めます。承認されたら `accepted`（承認済み）に変更します。
   - `date`: 作成または更新した当日の日付（YYYY-MM-DD）。
   - `decision-makers`: 意思決定に関わった人やエージェントの名前。
4. **内容を起草する**: アーキテクチャの議論に基づき、背景、決定要因、検討した選択肢、意思決定の結末、メリット・デメリットを記入します。
5. **インデックスにADRを登録する**: [README.md](../../../docs/decisions/README.md) のリストに新しいADRを追加します。
6. **レビューを依頼する**: 作成したADRファイルとREADMEの変更内容をユーザーに提案し、確認を得ます。

## ADRの更新および上書き (Supersede)
ある意思決定が古いADRを置き換える、または更新する場合：
1. 新しい意思決定に関する新しいADRを作成します（例：`0005-use-postgres-instead-of-sqlite.md`）。
2. （承認されたら）新しいADRのステータスを `accepted` にします。
3. 古いADRを更新します：
   - YAMLフロントマターの `status` を `superseded by ADR-NNNN` に変更します。
   - 概要、または「関連情報 (More Information)」セクションに、新しいADRへの参照リンクを追加します。
4. [README.md](../../../docs/decisions/README.md) のインデックスを更新し、ステータスの変更を反映します。

## ADRの廃止 (Deprecated)
ある意思決定が単に不要になり、新しい決定で置き換える必要もない場合：
1. 対象のADRのYAMLフロントマターの `status` を `deprecated` に変更します。
2. 背景や「関連情報 (More Information)」セクションに、この決定が不要（廃止）になった理由や経緯を記載します。
3. [README.md](../../../docs/decisions/README.md) のインデックスを更新し、ステータスの変更を反映します。
