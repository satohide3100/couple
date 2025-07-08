class AnniversaryController < ApplicationController
  include LiffAuthenticatable

  def index
    @anniversary_date = Date.new(2024, 7, 28)
    @today = Date.current
    @days_together = (@today - @anniversary_date).to_i
    @background_photo = CouplePhoto.current_background
    @male_profile = Profile.male_profile || Profile.new(profile_type: 'male', name: 'ひで', birthday: Date.new(1994, 8, 30))
    @female_profile = Profile.female_profile || Profile.new(profile_type: 'female', name: 'りな', birthday: Date.new(2001, 1, 10))
    
    # 固定の誕生日を設定
    @male_profile.birthday = Date.new(1994, 8, 30)
    @female_profile.birthday = Date.new(2001, 1, 10)
    
    calculate_milestones
  end

  def update
    if params[:couple_photo]
      @couple_photo = CouplePhoto.new(couple_photo_params)
      @couple_photo.is_background = true
      
      if @couple_photo.save
        # 古い背景写真を無効化
        CouplePhoto.where(is_background: true).where.not(id: @couple_photo.id).update_all(is_background: false)
        redirect_to anniversary_path, notice: '背景写真を更新しました'
      else
        redirect_to anniversary_path, alert: '写真のアップロードに失敗しました'
      end
    elsif params[:profile]
      @profile = Profile.find_or_initialize_by(profile_type: params[:profile][:profile_type])
      @profile.assign_attributes(profile_params)
      
      # 誕生日を固定値で設定
      if @profile.profile_type == 'male'
        @profile.birthday = Date.new(1994, 8, 30)
      else
        @profile.birthday = Date.new(2001, 1, 10)
      end
      
      if @profile.save
        redirect_to anniversary_path, notice: 'プロフィールを更新しました'
      else
        redirect_to anniversary_path, alert: 'プロフィールの更新に失敗しました'
      end
    else
      redirect_to anniversary_path, alert: '無効なリクエストです'
    end
  end

  private

  def couple_photo_params
    params.require(:couple_photo).permit(:image)
  end
  
  def profile_params
    params.require(:profile).permit(:name, :profile_type, :avatar)
  end

  def calculate_milestones
    @anniversary_date = Date.new(2024, 7, 28)
    @today = Date.current
    
    # 現在の経過月数を計算
    @current_months = months_between(@anniversary_date, @today)
    
    # 次の月数記念日を計算
    @next_month_milestone = @current_months + 1
    @next_month_date = @anniversary_date >> @next_month_milestone
    @days_to_next_month = (@next_month_date - @today).to_i
    
    # 年数記念日を計算
    @current_years = @today.year - @anniversary_date.year
    @current_years -= 1 if @today < @anniversary_date >> (@current_years * 12)
    
    @next_year_milestone = @current_years + 1
    @next_year_date = @anniversary_date >> (@next_year_milestone * 12)
    @days_to_next_year = (@next_year_date - @today).to_i
    
    # 特別な日数記念日（100日、200日など）
    calculate_special_days
  end

  def months_between(start_date, end_date)
    (end_date.year - start_date.year) * 12 + (end_date.month - start_date.month)
  end

  def calculate_special_days
    days_together = (@today - @anniversary_date).to_i
    
    # 100日刻みの記念日
    @special_days = []
    
    [100, 200, 300, 365, 500, 600, 700, 800, 900, 1000].each do |milestone|
      if days_together < milestone
        milestone_date = @anniversary_date + milestone.days
        days_until = (milestone_date - @today).to_i
        @special_days << {
          type: "#{milestone}日",
          date: milestone_date,
          days_until: days_until
        }
      end
    end
    
    # 一番近い記念日
    @next_special_day = @special_days.first
  end
end
