class PricePeriod < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
end
