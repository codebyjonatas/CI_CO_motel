class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :room
  # Permite que um service informe o motivo real de uma transição de status
  # (ex.: cancelamento) sem depender do mapeamento automático do RoomAuditable.
  attribute :room_status_trigger
end
