class Place < ApplicationRecord
  # acts_as_list 設定
  acts_as_list scope: :category

  # バリデーション
  validates :name, presence: true
  validates :visited, inclusion: { in: [true, false] }

  # アソシエーション
  belongs_to :category

  # スコープ
  scope :visited, -> { where(visited: true) }
  scope :unvisited, -> { where(visited: false) }
  scope :ordered, -> { order(:position) }
  scope :ordered_by_status, -> { order(visited: :asc, position: :asc) }

  # コールバック
  after_create_commit -> { broadcast_prepend_later_to [category, :places], target: "places" }
  after_update_commit -> { broadcast_replace_later_to [category, :places] }
  after_destroy_commit -> { broadcast_remove_to [category, :places] }

  # インスタンスメソッド
  def toggle_visited!
    update!(visited: !visited)
  end
end