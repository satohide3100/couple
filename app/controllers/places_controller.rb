class PlacesController < ApplicationController
  include LiffAuthenticatable
  
  before_action :set_place, only: [:update, :destroy, :toggle_visited, :move]

  def create
    @place = Place.new(place_params)

    if @place.save
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("places-list", partial: "dashboard/place_item", locals: { place: @place }),
            turbo_stream.replace("new_place_form", partial: "dashboard/place_form", locals: { category: @place.category, place: Place.new }),
            turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "行きたい場所を追加しました", type: "success" })
          ]
        }
        format.html { redirect_to dashboard_category_path(@place.category) }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: @place.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to dashboard_category_path(@place.category) }
      end
    end
  end

  def update
    if @place.update(place_params)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(@place),
            turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "更新しました", type: "success" })
          ]
        }
        format.html { redirect_to dashboard_category_path(@place.category) }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: @place.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to dashboard_category_path(@place.category) }
      end
    end
  end

  def destroy
    category = @place.category
    @place.destroy

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.remove(@place),
          turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "削除しました", type: "success" })
        ]
      }
      format.html { redirect_to dashboard_category_path(category) }
    end
  end

  def toggle_visited
    old_status = @place.visited?
    @place.toggle_visited!
    new_status = @place.visited?
    
    # カテゴリーの全場所を再取得（ステータス順）
    @places = @place.category.places.ordered_by_status

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace("places-list", 
            partial: "dashboard/places_list", 
            locals: { places: @places }
          ),
          turbo_stream.replace("toast", partial: "layouts/toast", locals: { 
            message: "「#{@place.name}」を#{new_status ? '訪問済み' : '未訪問'}にしました", 
            type: "success" 
          })
        ]
      }
      format.html { redirect_to dashboard_category_path(@place.category) }
    end
  end

  def move
    old_position = @place.position
    new_position = params[:position].to_i
    
    # デバッグ情報をセッションに保存してJavaScriptで表示
    session[:debug_info] = "移動: ID #{@place.id}, #{old_position}番目 → #{new_position}番目"
    
    begin
      @place.insert_at(new_position)
      @place.reload
      
      session[:debug_info] += " | 結果: 成功 (最終位置: #{@place.position})"
      render json: { status: 'success', old_position: old_position, new_position: @place.position }
    rescue => e
      session[:debug_info] += " | エラー: #{e.message}"
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    end
  end

  private

  def set_place
    @place = Place.find(params[:id])
  end

  def place_params
    params.require(:place).permit(:name, :memo, :visited, :category_id)
  end
end