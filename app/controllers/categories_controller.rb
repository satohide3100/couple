class CategoriesController < ApplicationController
  include LiffAuthenticatable
  
  before_action :set_category, only: [:update, :destroy, :move]

  def index
    @categories = Category.ordered
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.append("category-tabs", partial: "dashboard/category_tab", locals: { category: @category }),
            turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "カテゴリーを作成しました", type: "success" }),
            turbo_stream.replace("new_category_form", partial: "dashboard/category_form", locals: { category: Category.new })
          ]
        }
        format.html { redirect_to dashboard_category_path(@category) }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: @category.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to dashboard_category_path(@category) }
      end
    end
  end

  def update
    if @category.update(category_params)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("category_tab_#{@category.id}", partial: "dashboard/category_tab", locals: { category: @category }),
            turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "カテゴリーを更新しました", type: "success" })
          ]
        }
        format.html { redirect_to dashboard_category_path(@category) }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: @category.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to dashboard_category_path(@category) }
      end
    end
  end

  def destroy
    @category.destroy

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.remove("category_tab_#{@category.id}"),
          turbo_stream.replace("toast", partial: "layouts/toast", locals: { message: "カテゴリーを削除しました", type: "success" })
        ]
      }
      format.html { 
        first_category = Category.first
        if first_category
          redirect_to dashboard_category_path(first_category)
        else
          redirect_to dashboard_path
        end
      }
    end
  end

  def move
    new_position = params[:position].to_i
    old_position = @category.position
    
    @category.insert_at(new_position)
    
    respond_to do |format|
      format.turbo_stream {
        @categories = Category.ordered
        render turbo_stream: turbo_stream.replace("sortable-categories", partial: "sortable_categories", locals: { categories: @categories })
      }
      format.json { 
        render json: { 
          status: 'success',
          old_position: old_position,
          new_position: @category.reload.position,
          message: "カテゴリーを位置#{old_position}から#{@category.position}に移動しました"
        }
      }
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :icon_image)
  end
end