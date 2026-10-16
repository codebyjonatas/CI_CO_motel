class RoomStatusLog < ApplicationRecord
  enum :trigger, {
    check_in: 0,
    check_out: 1,
    cancel: 2,
    maintenance_start: 3,
    maintenance_end: 4,
    manual: 5
  }

  # from_status/to_status são inteiros; os enums garantem que a atribuição de
  # strings ("available", "occupied", ...) seja convertida para o valor correto
  # (sem isso, "occupied".to_i vira 0 e todo log registrava o mesmo status).
  enum :from_status, Room.statuses, prefix: true
  enum :to_status, Room.statuses, prefix: true

  belongs_to :room
  belongs_to :stay, optional: true
  belongs_to :user

  scope :recent, -> { order(created_at: :desc) }
  scope :for_room, ->(room) { where(room: room) }
  scope :for_stay, ->(stay) { where(stay: stay) }
end
