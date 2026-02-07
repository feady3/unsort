# unsort

メモを自由に書き溜め、MemU APIによる要約・クラスタリングで「Reflect」タブに整理して閲覧できるアプリです。人物に関する情報だけでなく、小説のアイデア、勉強・仕事の計画・タスクなど多様なカテゴリを扱います。

## 概要
- Writeタブでメモを入力すると、MemUに送信されて過去の記録と照合・要約されます
- Reflectタブでは、カテゴリ（人物／ローカル／MemU）ごとにまとまった情報を日本語の箇条書きで閲覧できます
- 手動カテゴリの作成・削除、メモの削除・並べ替え、カテゴリの並べ替えに対応しています
- 重複したMemUの要約は圧縮・集約表示され、読みやすく整理されます

## 主な機能
- MemU API連携（送信・分類・取得）とReflectタブへの同期
- 人物以外のカテゴリ（アイデア／計画／タスクなど）をローカルにクラスタリング
- 手動カテゴリの作成・削除、メモの割り当て
- メモ／カテゴリの削除・非表示・並べ替え
- MemU要約の重複圧縮と日本語箇条書き表示
- MemUメモをLocalメモより上位に表示

## 主要ファイル
- [LocalStorageService.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/services/LocalStorageService.swift): クラスタ・メモ・ユーザ設定の永続化と並べ替えロジック
- [MemUService.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/services/MemUService.swift): MemU APIの呼び出し（memorize/retrieve）、日本語箇条書きのクエリ整形
- [ClustersView.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/views/ClustersView.swift): ReflectタブUI、MemU要約の表示、セクション順序（MemUを上→Local）
- [WriteMemoView.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/views/WriteMemoView.swift): メモ投稿とMemU送信のフロー
- [MemoModels.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/models/MemoModels.swift): メモ／クラスタ／手動カテゴリ／ユーザ設定モデル

## 使い方
- メモの記録
  - Writeタブで自然文を入力して送信します
  - 人名や日付などを含むと、MemUが過去のメモと照合し人物／予定情報として要約します
- 要約の閲覧
  - Reflectタブでカテゴリ別に要約を確認します（MemU／Local／人物の各セクション）
  - MemUの要約は日本語の箇条書きで表示され、重複は集約されます
- 編集操作
  - スワイプで削除・非表示、ドラッグで並べ替え
  - 編集モードで手動カテゴリの作成・削除、メモの割り当てが可能です

## 技術メモ
- SwiftUIの依存が必要な`move(fromOffsets:toOffset:)`の代替として、独自の`applyMove()`をサービス層に実装
  - 実装箇所: [LocalStorageService.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/services/LocalStorageService.swift)
- ForEachのID衝突を避けるため、`enumerated()`のインデックスをIDに使用
  - 実装箇所: [ClustersView.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/views/ClustersView.swift)
- Reflectタブの同期は初回限定条件を撤廃し、表示時に同期処理を実行
  - 実装箇所: [ClustersView.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/views/ClustersView.swift)
- MemUの要約は日本語の箇条書きで表示し、「The user…」などの不要文言は除去
  - 実装箇所: [MemUService.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/services/MemUService.swift), [ClustersView.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/views/ClustersView.swift)

## セキュリティ・設定
- MemUのAPIキーやエンドポイントはコードにハードコードしないでください
  - 実装や設定の参照: [MemUService.swift](file:///Users/sasamotokazutoyo/Documents/unsort/unsort/services/MemUService.swift)
  - 秘密情報は環境変数やビルド設定など安全な経路で管理してください

## 開発ガイド
- ビルド／実行
  - Xcodeでプロジェクトを開き、ターゲットを選択してRunしてください
- 方針
  - 既存のコードスタイル／命名規則に合わせて実装してください
  - ログに秘密情報を出力しないでください

## トラブルシューティング
- ReflectにMemUの要約が表示されない
  - ネットワーク接続とMemU側の応答を確認し、アプリ再表示で同期を試してください
- 並べ替えが反映されない
  - 編集モードで一度操作後、再表示して反映状況を確認してください

## ライセンス
このリポジトリのライセンスは未設定です。必要に応じて追加してください。
