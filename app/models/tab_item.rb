class TabItem < ApplicationRecord
  enum :status, { active: 0, voided: 1, transferred: 2 }

  belongs_to :tab
  belongs_to :product
  belongs_to :added_by, class_name: "User"
  belongs_to :voided_by, class_name: "User", optional: true

  has_many :audits, class_name: "TabItemAudit", dependent: :destroy

  scope :ordered, -> { order(created_at: :desc) }

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }
  validate :unit_price_matches_product_price, on: :create

  before_validation :calculate_total_price
  before_validation :sanitize_notes

  def void!(user:, reason:)
    raise "Item já estornado" if voided?
    raise "Comanda não permite estorno (status: #{tab.status})" unless tab.open? || tab.closed?

    transaction do
      audits.create!(
        action: :void,
        user: user,
        reason: reason,
        previous_state: attributes.slice("status", "quantity", "unit_price", "total_price"),
        tab_status_at_time: tab.status_before_type_cast
      )

      update!(status: :voided, voided_by: user, voided_at: Time.current, notes: reason)
      tab.recalculate_totals!
    end
  end

  private

  def calculate_total_price
    self.total_price = quantity * unit_price
  end

  def sanitize_notes
    self.notes = Rails::Html::FullSanitizer.new.sanitize(notes) if notes.present?
  end

  def unit_price_matches_product_price
    return unless product && unit_price
    if (unit_price - product.price).abs > 0.01
      errors.add(:unit_price, "não corresponde ao preço atual do produto")
    end
  end
end
