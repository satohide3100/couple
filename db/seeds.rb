# 開発環境用のシードデータ
if Rails.env.development?
  # 既存データをクリア
  Place.destroy_all
  Category.destroy_all

  # カテゴリーとサンプルデータ
  categories_data = [
    {
      name: "レストラン・カフェ",
      places: [
        { name: "bills 表参道", memo: "世界一の朝食を食べたい", visited: true },
        { name: "ブルーボトルコーヒー 清澄白河", memo: "本店でコーヒーを楽しむ", visited: false },
        { name: "つるとんたん 六本木", memo: "遅い時間でも行ける", visited: false }
      ]
    },
    {
      name: "国内旅行",
      places: [
        { name: "京都 嵐山", memo: "紅葉の時期に行きたい", visited: false },
        { name: "沖縄 美ら海水族館", memo: "ジンベエザメを見る", visited: true },
        { name: "北海道 富良野", memo: "ラベンダー畑を見に行く", visited: false }
      ]
    },
    {
      name: "アクティビティ",
      places: [
        { name: "富士急ハイランド", memo: "絶叫マシンに挑戦", visited: false },
        { name: "teamLab Borderless", memo: "幻想的な空間を体験", visited: true },
        { name: "パラグライダー体験", memo: "空を飛んでみたい", visited: false }
      ]
    }
  ]

  categories_data.each do |category_data|
    category = Category.create!(name: category_data[:name])
    
    category_data[:places].each_with_index do |place_data, index|
      category.places.create!(
        name: place_data[:name],
        memo: place_data[:memo],
        visited: place_data[:visited],
        position: index + 1
      )
    end
  end

  puts "シードデータの投入が完了しました。"
  puts "カテゴリー数: #{Category.count}"
  puts "場所数: #{Place.count}"
end
