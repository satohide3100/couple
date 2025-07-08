module CategoriesHelper
  def category_color(name)
    colors = {
      "レストラン・カフェ" => "#ef4444", # red-500
      "国内旅行" => "#3b82f6", # blue-500
      "アクティビティ" => "#10b981", # emerald-500
      "海外旅行" => "#8b5cf6", # violet-500
      "ショッピング" => "#f59e0b", # amber-500
      "映画・エンタメ" => "#ec4899", # pink-500
      "スポーツ" => "#06b6d4", # cyan-500
      "学習・読書" => "#6366f1" # indigo-500
    }
    
    colors[name] || "#6b7280" # gray-500
  end

  def category_icon(category)
    # If category is a string (legacy usage), return default icon
    if category.is_a?(String)
      return default_category_icon(category)
    end
    
    # Return uploaded image if available
    if category.icon_image.attached?
      return image_tag(category.icon_image, class: "w-full h-full object-cover rounded-full")
    end
    
    # Return custom emoji icon if available, otherwise default
    category.icon.presence || default_category_icon(category.name)
  end

  def default_category_icon(name)
    icons = {
      "レストラン・カフェ" => "🍽️",
      "国内旅行" => "🗾",
      "アクティビティ" => "🎯",
      "海外旅行" => "✈️",
      "ショッピング" => "🛍️",
      "映画・エンタメ" => "🎬",
      "スポーツ" => "⚽",
      "学習・読書" => "📚"
    }
    
    icons[name] || "📝"
  end
end