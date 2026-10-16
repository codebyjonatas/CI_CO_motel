class Product < ApplicationRecord
  enum :category, { beer: 0, spirits: 1, soft_drink: 2, snack: 3, water: 4, other: 99 }

  has_many :price_rules, class_name: "ProductPriceRule", dependent: :destroy
  has_many :tab_items, dependent: :restrict_with_error
  has_many :tabs, through: :tab_items

  scope :active, -> { where(active: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :ordered, -> { order(:category, :name) }

  validates :code, :name, :category, :price, presence: true
  validates :code, uniqueness: true
  validates :price, numericality: { greater_than: 0 }
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0 }

  def current_price(at: Time.current)
    price_rules.for_time(at).first&.price || price
  end
end
