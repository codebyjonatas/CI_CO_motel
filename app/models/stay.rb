class Stay < ApplicationRecord
  belongs_to :room
  belongs_to :user
  belongs_to :price_period

  enum :status, { active: 0, completed: 1, cancelled: 2 }

  validates :check_in, presence: true
  validates :date, presence: true
  validates :week_number, presence: true
  validates :total_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :set_date_and_week, on: :create
  before_validation :set_total_value_from_period, on: :create

  scope :today, -> { where(date: Date.current) }
  scope :active_stays, -> { where(status: :active) }
  scope :ordered, -> { order(check_in: :desc) }

  private

  def set_date_and_week
    self.date = check_in.to_date if check_in.present?
    self.week_number = date&.cweek
  end

 def set_total_value_from_period
    return if price_period.blank?
    self.total_value = price_period.price
  end
end
