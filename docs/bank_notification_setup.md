# 入金通知（freee会計 → LINE）セットアップ手順

freee会計に連携されている銀行口座の入出金明細を定期取得し、
**入金があったら LINE 公式アカウントから一斉配信**する機能。

```
GMO銀行 ──(freee自動同期)──▶ freee会計
                                  │  Railway Cron が定期 poll
                                  ▼
                       /api/1/wallet_txns (entry_side=income)
                                  │ freee-<id> で冪等化 → BankDeposit 保存
                                  ▼
                       LINE Messaging API (broadcast) ──▶ 友だち全員
```

## ⚠️ リアルタイム性について

これは **即時通知ではありません**。遅延は2段で積み上がります:

1. freee側の銀行自動同期の間隔（通常1日数回。手動同期で短縮可）
2. 本アプリのポーリング間隔（Railway Cron の設定次第）

「振込された瞬間」に近づけたい場合は、将来 GMO API が承認されれば Webhook 方式
（即時）へ移行するのが本筋。現状は freee 経由のため上記の遅延を前提とする。

freee会計の Webhook(β) は申請/経費精算/支払依頼のみ対応で、口座明細・入金の
イベントは存在しないため、ポーリング以外の手段はない。

---

## 1. freee アプリ（OAuth）

client_id / client_secret は取得済み前提。

1. freeeアプリの設定で **コールバックURL** を環境に合わせる:
   - 手動認可（推奨・既定）: `urn:ietf:wg:oauth:2.0:oob`（ブラウザに認可コードが表示される）
   - `FREEE_REDIRECT_URI` をアプリ設定と一致させること。
2. `.env` / Railway Variables に設定（`.env.example` 参照）:
   `FREEE_CLIENT_ID` / `FREEE_CLIENT_SECRET` / `FREEE_REDIRECT_URI`

## 2. 初回認可（リフレッシュトークン取得）

freeeのアクセストークンは約6時間で失効し、リフレッシュ時に refresh_token も
**毎回ローテーション**する。本実装は `freee_credentials` テーブルに保存し、
ポーリング時に自動リフレッシュ・自動保存する。初回だけ手動で認可する:

```bash
bin/rails freee:authorize_url        # 表示URLをブラウザで開いて事業所を認可
bin/rails 'freee:exchange[ここに認可コード]'   # トークン取得・保存
```

> 注意: トークンはDB保存。本番(Railway)で認可する場合は本番環境のDBに保存される
> 必要がある（本番コンテナで `bin/rails 'freee:exchange[...]'` を実行）。

## 3. 監視対象の特定

```bash
bin/rails freee:list_companies       # → FREEE_COMPANY_ID
bin/rails freee:list_walletables     # → FREEE_WALLETABLE_ID / TYPE(bank_account)
```

出力のIDを `.env` / Railway Variables に設定:
`FREEE_COMPANY_ID` / `FREEE_WALLETABLE_ID` / `FREEE_WALLETABLE_TYPE`

## 4. LINE Messaging API

設定済み（発信元: 公式アカウント **@966dhnab**「法人口座通知用」/ channelId 2010119564）。

| 変数 | 用途 |
|---|---|
| `LINE_CHANNEL_ACCESS_TOKEN` | 送信用（必須） |
| `LINE_DELIVERY_MODE` | `broadcast`（既定/友だち全員） または `push` |
| `LINE_NOTIFY_USER_ID` | `push` 方式のときのみ |

`broadcast` は @966dhnab を友だち追加した全員に届く。

## 5. セルフチェック

```bash
bin/rails freee:check_config
```

`freeeポーリング準備OK` と `LINE送信準備OK` が true なら準備完了。

## 6. ポーリング実行（Railway Cron）

Railway の **Cron Schedule**（サービス設定 → Settings → Cron）で、
別プロセスとして定期実行する。実行コマンド:

```
bin/rails freee:poll_deposits
```

推奨スケジュール例（freee同期が日数回なので過剰ポーリング不要）:

```
*/30 * * * *      # 30分ごと
```

`freee:poll_deposits` は毎回 **直近 `FREEE_LOOKBACK_DAYS` 日分**（既定3日）の
明細を取得し直し、`BankDeposit` の `message_id`(=`freee-<wallet_txn id>`)で
重複排除する。これにより freee の遅延同期・後追い登録があっても取りこぼさず、
かつ二重通知しない。

> Railway Cron はメインのWebサービスとは別の使い切りプロセスとして起動するため、
> アプリ内スケジューラやワーカー常駐は不要。

## 7. 障害時の再送

LINE送信に失敗した入金は `bank_deposits` に保存され `notified_at` が空のまま残る。
次回以降の `freee:poll_deposits` でも、その明細は「保存済み(duplicate)」となり
**再送されない**点に注意（取りこぼし扱い）。再送が必要なら未通知レコードを対象に
`BankDepositNotifier#deliver` を回す運用タスクを別途追加する想定（必要なら実装）。

## 8. データモデル / 実装メモ

- `bank_deposits`: `message_id` 一意。`source="freee"`。`raw_payload` に
  wallet_txn 全体をJSON保存（監査用）。
- HTTPは依存追加を避け `Net::HTTP`。`Freee::Client#request` を差し替えて単体テスト。
- 送信は同期。短時間に大量入金がある用途ではジョブ化（Sidekiq等）の余地あり。
- freee APIにはレート制限あり。30分間隔・lookback数日程度なら問題ない範囲。
- 旧GMOあおぞらWebhook実装は本対応で削除済み（承認後に再導入する場合は再実装）。
