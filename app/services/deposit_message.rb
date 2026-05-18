# 入金1件から LINE Flex Message を組み立てる（ダーク×ネオンの近未来UI）。
# 入力はソース非依存のダックタイプ（amount / remitter_name / value_date /
# remarks / event_timestamp）。現供給元は Freee::DepositTxn。
class DepositMessage
  include ActionView::Helpers::NumberHelper

  BG = "#0A0E14"        # ほぼ黒のディープネイビー
  NEON = "#00E5C0"      # ネオンミント（アクセント）
  WHITE = "#F2F5F7"
  MUTED = "#5A6B7B"     # ラベル等の控えめ色
  FAINT = "#33404D"     # 区切り/フッター
  PANEL = "#101722"     # パネル地

  def initialize(deposit)
    @deposit = deposit
  end

  # LINE Messaging API の messages 配列（Flex 1枚）
  def to_line_messages
    [{type: "flex", altText: alt_text, contents: bubble}]
  end

  # 通知バナー/フォールバック用の簡潔テキスト
  def alt_text
    "💰 入金 #{formatted_amount}#{remitter_suffix}"
  end

  private

  def bubble
    {
      type: "bubble",
      size: "mega",
      body: {
        type: "box",
        layout: "vertical",
        backgroundColor: BG,
        paddingAll: "22px",
        spacing: "none",
        contents: [
          status_row,
          {type: "text", text: "INCOMING TRANSFER", color: MUTED,
           size: "xxs", weight: "bold", margin: "xl"},
          {type: "text", text: "入金を検知", color: WHITE,
           size: "lg", weight: "bold", margin: "sm"},
          amount_panel,
          detail_table,
          footer
        ]
      },
      styles: {body: {backgroundColor: BG}}
    }
  end

  # ● LIVE  ……  freee → LINE
  def status_row
    {
      type: "box",
      layout: "horizontal",
      contents: [
        {type: "text", text: "● LIVE", color: NEON, size: "xxs",
         weight: "bold", flex: 0},
        {type: "text", text: "freee → LINE", color: FAINT, size: "xxs",
         align: "end"}
      ]
    }
  end

  # 金額を囲うネオン縁のパネル
  def amount_panel
    {
      type: "box",
      layout: "vertical",
      margin: "xl",
      paddingAll: "16px",
      backgroundColor: PANEL,
      cornerRadius: "12px",
      borderColor: NEON,
      borderWidth: "1px",
      contents: [
        {type: "text", text: "AMOUNT", color: MUTED, size: "xxs",
         weight: "bold"},
        {type: "text", text: formatted_amount, color: NEON,
         size: "4xl", weight: "bold", margin: "sm"}
      ]
    }
  end

  def detail_table
    rows = detail_rows
    return {type: "filler"} if rows.empty?

    {
      type: "box",
      layout: "vertical",
      margin: "xl",
      spacing: "md",
      contents: rows
    }
  end

  def detail_rows
    rows = []
    rows << row("振込人", @deposit.remitter_name) if @deposit.remitter_name.present?
    rows << row("入金日", @deposit.value_date)
    remarks = @deposit.remarks.to_s.strip
    rows << row("摘要", remarks) if remarks.present?
    rows
  end

  # ▸ ラベル(左・控えめ) … 値(右・折返し・白)
  def row(label, value)
    {
      type: "box",
      layout: "horizontal",
      contents: [
        {type: "text", text: "▸ #{label}", color: MUTED, size: "sm", flex: 3},
        {type: "text", text: present(value), color: WHITE, size: "sm",
         flex: 6, wrap: true, align: "end"}
      ]
    }
  end

  def footer
    {
      type: "box",
      layout: "vertical",
      margin: "xl",
      contents: [
        {type: "box", layout: "vertical", height: "1px",
         backgroundColor: FAINT, contents: [{type: "filler"}]},
        {type: "text", text: footer_text, color: FAINT, size: "xxs",
         align: "end", margin: "md"}
      ]
    }
  end

  def footer_text
    ts = @deposit.try(:event_timestamp)
    stamp = ts.respond_to?(:strftime) ? ts.strftime("%Y.%m.%d %H:%M") : @deposit.value_date
    "SYNCED · #{stamp}"
  end

  def formatted_amount
    yen = Integer(@deposit.amount, exception: false)
    return "#{@deposit.amount}円" if yen.nil?

    "¥#{number_with_delimiter(yen)}"
  end

  def remitter_suffix
    @deposit.remitter_name.present? ? "（#{@deposit.remitter_name}）" : ""
  end

  def present(value)
    s = value.to_s.strip
    s.empty? ? "-" : s
  end
end
