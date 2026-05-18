class CreateBankDeposits < ActiveRecord::Migration[7.1]
  def change
    create_table :bank_deposits do |t|
      # GMOあおぞらが採番する一意のメッセージID。重複配信の冪等キー。
      t.string :message_id, null: false

      # 入金明細の主要項目（LINE通知の本文に使う）
      t.string :amount, null: false                # depositAmount（円・文字列）
      t.string :remitter_name                       # remitterNameKana 振込依頼人名カナ
      t.string :value_date                          # valueDate 起算日 YYYY-MM-DD
      t.string :transaction_date                    # transactionDate 取引日
      t.string :va_account_number                   # vaAccountNumber 入金された仮想口座番号
      t.string :va_account_name                     # vaAccountNameKana
      t.string :payment_bank_name                   # paymentBankName 仕向金融機関
      t.text   :remarks                             # remarks 摘要
      t.datetime :event_timestamp                   # timestamp（イベント生成日時）

      # LINE通知の状態管理（送信失敗時の再送用）
      t.datetime :notified_at

      # 監査用に受信ペイロード全体を保存（pg/sqlite両対応のためtext）
      t.text :raw_payload, null: false

      t.timestamps
    end

    add_index :bank_deposits, :message_id, unique: true
    add_index :bank_deposits, :notified_at
  end
end
