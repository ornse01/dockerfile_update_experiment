# アーキテクチャ意思決定記録 (Architectural Decisions)

このリポジトリでは、Markdown Architectural Decision Records (MADR) 形式を使用して、アーキテクチャや設計に関する重要な意思決定を記録します。

## フォーマットとルール
- **テンプレート**: テンプレートファイルは [adr-template.md](adr-template.md) にあります。
- **ファイル名**: `NNNN-kebab-case-title.md` というパターンを使用します。`NNNN` は `0000` から始まる4桁の連番です。
- **ステータスのライフサイクル**:
  - `proposed`: 提案され、現在議論中の状態。
  - `accepted`: 合意され、現在有効な状態。
  - `rejected`: 提案されたが、採用されなかった状態。
  - `deprecated`: 古くなり、現在では考慮されなくなった状態。
  - `superseded by ADR-NNNN`: 新しい意思決定（ADR-NNNN）によって置き換えられた状態。

## 意思決定のインデックス (Index of Decisions)

* [ADR-0000: Markdown Architectural Decision Records (MADR) の導入](0000-use-markdown-architectural-decision-records.md) - **accepted**
* [ADR-0001: ベースイメージの自動更新およびリリースフロー](0001-base-image-update-workflow.md) - **accepted**

