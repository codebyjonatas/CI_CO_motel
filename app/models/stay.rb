class Stay < ApplicationRecord
  belongs_to :room
  belongs_to :user
  belongs_to :price_period

  has_many :tabs, dependent: :restrict_with_error
  has_many :stay_guests, dependent: :destroy
  has_many :room_status_logs, dependent: :nullify
  has_one :main_guest, -> { where(main_guest: true) }, class_name: "StayGuest"

  accepts_nested_attributes_for :stay_guests, allow_destroy: true, reject_if: :all_blank

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

  def active_tab
    tabs.where(status: [ :open, :closed ]).order(:created_at).last
  end

  def tab_balance
    tabs.where(status: [ :open, :closed ]).sum(:total)
  end

  def total_account_balance
    (total_value || 0) + tab_balance
  end

  def update_account_balance!
    touch(:updated_at)
  end

  def can_check_out?
    true
  end

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
