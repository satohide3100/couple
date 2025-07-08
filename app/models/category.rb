class Category < ApplicationRecord
  # acts_as_listで並び替え機能を追加
  acts_as_list

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # アソシエーション
  has_many :places, dependent: :destroy
  mount_uploader :icon_image, ImageUploader

  # スコープ
  scope :with_places_count, -> { left_joins(:places).group(:id).select("categories.*, COUNT(places.id) as places_count") }
  scope :ordered, -> { order(:position) }

  # インスタンスメソッド
  def visited_places_count
    places.visited.count
  end

  def unvisited_places_count
    places.unvisited.count
  end

  def completion_rate
    return 0 if places.count == 0
    (visited_places_count.to_f / places.count * 100).round
  end
end