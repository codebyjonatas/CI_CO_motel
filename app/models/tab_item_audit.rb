class TabItemAudit < ApplicationRecord
  enum :action, { void: 0, price_override: 1, quantity_change: 2, transfer: 3 }

  belongs_to :tab_item
  belongs_to :user

  validates :previous_state, presence: true
  validates :tab_status_at_time, presence: true
end
