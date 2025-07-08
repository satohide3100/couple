class DashboardController < ApplicationController
  include LiffAuthenticatable
  
  before_action :set_categories

  def index
    @current_category = @categories.first
    @places = @current_category&.places&.ordered_by_status || Place.none
    @new_place = Place.new
    @new_category = Category.new
    
    apply_filter
  end

  def show
    @current_category = @categories.find(params[:category_id])
    @places = @current_category.places.ordered_by_status
    @new_place = Place.new
    @new_category = Category.new
    
    apply_filter
    
    respond_to do |format|
      format.html { render :index }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace("category-tabs", partial: "category_tabs", locals: { categories: @categories, current_category: @current_category }),
          turbo_stream.replace("filter-section", partial: "filter_section", locals: { current_category: @current_category }),
          turbo_stream.replace("places-list", partial: "places_list", locals: { places: @places })
        ]
      }
    end
  end

  private

  def set_categories
    @categories = Category.includes(:places).ordered
  end

  def apply_filter
    return unless @current_category

    case params[:filter]
    when "visited"
      @places = @places.visited
    when "unvisited"
      @places = @places.unvisited
    end
  end
end