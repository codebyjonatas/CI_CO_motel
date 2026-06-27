class Room < ApplicationRecord
  has_many :stays, dependent: :restrict_with_error

  enum :status, { available: 0, occupied: 1, maintenance: 2 }

  validates :number, presence: true, uniqueness: true
  validates :daily_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
