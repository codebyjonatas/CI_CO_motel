class StayAuditLog < ApplicationRecord
  enum :audit_action, { value_change: 0, observation_change: 1 }

  belongs_to :stay
  belongs_to :user

  validates :field_name, presence: true
  validates :audit_action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_stay, ->(stay) { where(stay: stay) }
  scope :for_field, ->(field) { where(field_name: field) }
end
