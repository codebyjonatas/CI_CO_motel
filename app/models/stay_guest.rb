class StayGuest < ApplicationRecord
  enum :document_type, { cpf: 0, rg: 1, passport: 2, other: 99 }

  belongs_to :stay

  validates :full_name, presence: true
  validates :main_guest, uniqueness: { scope: :stay_id, if: :main_guest? }
end
