class SetPositionForExistingCategories < ActiveRecord::Migration[7.1]
  def up
    # 既存のカテゴリーにposition値を設定
    Category.where(position: nil).order(:created_at).each_with_index do |category, index|
      category.update_column(:position, index + 1)
    end
  end

  def down
    # ロールバック時はposition値をnullに戻す
    Category.update_all(position: nil)
  end
end
