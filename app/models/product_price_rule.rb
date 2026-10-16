class ProductPriceRule < ApplicationRecord
  belongs_to :product

  scope :active, -> { where(active: true) }
  scope :for_time, ->(time = Time.current) {
    active
      .where("valid_from IS NULL OR valid_from <= ?", time.to_date)
      .where("valid_until IS NULL OR valid_until >= ?", time.to_date)
      .where("(days_of_week = '{}' OR ? = ANY(days_of_week))", time.wday)
      .where("(starts_at IS NULL AND ends_at IS NULL) OR (starts_at <= ? AND ends_at >= ?)", time.strftime("%H:%M"), time.strftime("%H:%M"))
      .order(priority: :desc)
  }

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :priority, numericality: { greater_than_or_equal_to: 0 }

  def applies_at?(time = Time.current)
    return false unless active?
    return false if valid_from && time.to_date < valid_from
    return false if valid_until && time.to_date > valid_until
    return false if days_of_week.any? && !days_of_week.include?(time.wday)
    return false if starts_at && ends_at && !(time.strftime("%H:%M") >= starts_at.strftime("%H:%M") && time.strftime("%H:%M") <= ends_at.strftime("%H:%M"))
    true
  end
end
