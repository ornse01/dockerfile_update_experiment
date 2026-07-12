---
status: accepted
date: 2026-07-12
decision-makers: srone, Antigravity
---

# Markdown Architectural Decision Records (MADR) の導入

## 背景と問題の本質 (Context and Problem Statement)

このリポジトリにおけるアーキテクチャや設計に関する重要な意思決定を、構造化され、バージョン管理され、かつ軽量で読みやすい方法で記録・追跡する手段が必要です。その場しのぎの意思決定は、時間の経過とともに設計の文脈（コンテキスト）の喪失や技術的負債につながります。

## 決定要因 (Decision Drivers)

* メンテナンス性: ドキュメントをコードベースの近く（Gitリポジトリ内）に保持すること。
* 可読性: 標準的なMarkdown形式を使用すること。
* 履歴追跡: ステータス（例：proposed, accepted, superseded）や変更履歴を時間の経過とともに容易に追跡できること。

## 検討した選択肢 (Considered Options)

* Markdown Architectural Decision Records (MADR)
* Wiki/Confluence等の外部ツールによるドキュメント管理
* 非構造的なテキストファイル、または明示的なADRの不導入

## 意思決定の結末 (Decision Outcome)

選択されたオプション: "Markdown Architectural Decision Records (MADR)"
理由: 軽量なMarkdownテンプレートが提供されており、Gitによるバージョン管理やPull Request（PR）のフローと非常に親和性が高く、リポジトリ内でのメンテナンスが容易であるため。

### 影響・結果 (Consequences)

* 良い点: 意思決定がコードと同時にバージョン管理されます。
* 良い点: テンプレートが開発者に対して、意思決定の理由（Why）とトレードオフを説明するようガイドします。
* 悪い点: ファイルを手動で作成し、インデックス（目次）を最新に保つための手動の運用コストが発生します。

## 各選択肢のメリットとデメリット (Pros and Cons of the Options)

### Markdown Architectural Decision Records (MADR)

MADRは、MarkdownベースのADRの構造化されたフォーマットを定義します。

* 良い点: プレーンテキストとしても、レンダリングされたHTMLとしても軽量で読みやすい。
* 良い点: ステータスや日付を管理するためのメタデータブロック（YAMLフロントマター）が含まれている。
* 良い点: Gitリポジトリに保存されるため、PRによるコードレビューワークフローと統合できる。
* 悪い点: インデックスファイルを最新に保つために、ツールや手動の規律が必要。

### Wiki/Confluence等の外部ツールによるドキュメント管理

外部のWikiに意思決定を記述する方法。

* 良い点: 開発者以外のメンバーも簡単にアクセスできる。
* 悪い点: コードベースと切り離されているため、情報が古くなりやすい。
* 悪い点: GitのブランチやPRのワークフローと連携できない。

### 非構造的なテキストファイル、または明示的なADRの不導入

* 良い点: 初期コストがほぼゼロである。
* 悪い点: 重要なアーキテクチャ上の決定が忘れ去られ、その合理的根拠が失われる。

## 関連情報 (More Information)

公式のMADR仕様を参照してください: https://adr.github.io/madr/
