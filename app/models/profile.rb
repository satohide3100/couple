class Profile < ApplicationRecord
  has_one_attached :avatar
  
  validates :name, presence: true
  validates :profile_type, presence: true, inclusion: { in: %w[male female] }
  
  scope :male, -> { where(profile_type: 'male') }
  scope :female, -> { where(profile_type: 'female') }
  
  def self.male_profile
    male.first
  end
  
  def self.female_profile
    female.first
  end
  
  def next_birthday
    return nil unless birthday
    
    today = Date.current
    this_year_birthday = Date.new(today.year, birthday.month, birthday.day)
    
    if this_year_birthday >= today
      this_year_birthday
    else
      Date.new(today.year + 1, birthday.month, birthday.day)
    end
  end
  
  def days_until_birthday
    return nil unless next_birthday
    
    (next_birthday - Date.current).to_i
  end
  
  def age
    return nil unless birthday
    
    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < Date.new(today.year, birthday.month, birthday.day)
    age
  end
end
