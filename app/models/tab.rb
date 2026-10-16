class Tab < ApplicationRecord
  enum :status, {
    open: 0,      # aberta, aceitando lançamentos
    closed: 1,    # fechada (não aceita mais itens), aguardando pagamento
    paid: 2,      # paga (quitada)
    cancelled: 3, # cancelada/estornada totalmente
    transferred: 4 # transferida para outro quarto/stay
  }

  belongs_to :stay, optional: true
  belongs_to :room
  belongs_to :opened_by, class_name: "User"
  belongs_to :closed_by, class_name: "User", optional: true

  has_many :tab_items, dependent: :destroy
  has_many :active_items, -> { where(status: :active) }, class_name: "TabItem"
  has_many :products, through: :tab_items

  validates :room, presence: true
  validates :guest_identifier, presence: true, if: -> { stay_id.blank? }
  validates :subtotal, :discount, :total, numericality: { greater_than_or_equal_to: 0 }

  scope :for_room, ->(room) { where(room: room) }
  scope :for_stay, ->(stay) { where(stay: stay) }
  scope :walk_ins, -> { where(stay_id: nil) }
  scope :active_tabs, -> { where(status: [ :open, :closed ]) }
  scope :pending_payment, -> { where(status: [ :closed ]) }
  scope :ordered, -> { order(created_at: :desc) }

  before_validation :set_defaults, on: :create

  def walk_in?
    stay_id.blank?
  end

  def can_add_items?
    open?
  end

  def recalculate_totals!
    self.subtotal = active_items.sum(:total_price)
    self.total = subtotal - discount
    save!
  end

  def close!(user:, notes: nil)
    transaction do
      update!(status: :closed, closed_by: user, closed_at: Time.current, notes: notes)
      stay&.update_account_balance!
    end
  end

  def pay!(user:, notes: nil)
    transaction do
      update!(status: :paid, closed_by: user, paid_at: Time.current, notes: notes)
      stay&.update_account_balance!
    end
  end

  def cancel!(user:, reason:)
    transaction do
      update!(status: :cancelled, closed_by: user, closed_at: Time.current, notes: reason)
      active_items.each { |item| item.update!(status: :voided, voided_by: user, voided_at: Time.current, notes: reason) }
      stay&.update_account_balance!
    end
  end

  def transfer_to!(target_room:, target_stay:, user:, notes: nil)
    raise "Comanda não está aberta" unless open?
    raise "Quarto de destino não disponível" unless target_room.available? || target_room.occupied?

    transaction do
      new_tab = Tab.create!(
        stay: target_stay,
        room: target_room,
        opened_by: user,
        guest_identifier: guest_identifier,
        status: :open,
        notes: "Transferida da comanda ##{id}. #{notes}"
      )

      active_items.each do |item|
        new_tab.tab_items.create!(
          product: item.product,
          added_by: user,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total_price: item.total_price,
          notes: "Transferido da comanda ##{id}"
        )
        item.update!(status: :transferred)
      end

      # Recalcula os totais da comanda de destino (senão ela fica com R$ 0,00 no dashboard)
      new_tab.recalculate_totals!

      update!(
        status: :transferred,
        subtotal: 0,
        discount: 0,
        total: 0,
        notes: "Transferida para comanda ##{new_tab.id}. #{notes}"
      )
      new_tab
    end
  end

  def apply_discount!(user:, percent: 0, absolute: 0)
    DiscountLimit.validate!(
      user: user,
      discount_percent: percent,
      discount_absolute: absolute,
      tab_subtotal: subtotal
    )

    if percent.positive?
      self.discount = subtotal * (percent / 100.0)
    else
      self.discount = absolute
    end

    recalculate_totals!
  end

  private

  def set_defaults
    self.subtotal ||= 0
    self.discount ||= 0
    self.total ||= 0
    self.status ||= :open
  end
end
