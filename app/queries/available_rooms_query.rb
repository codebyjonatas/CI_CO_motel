# Encapsula as consultas de disponibilidade de quartos, considerando o ciclo
# de limpeza/quarentena. Substitui a lógica que ficava inline nas views.
class AvailableRoomsQuery
  def initialize(scope = Room.order(:number))
    @scope = scope
  end

  # Quartos aptos a receber check-in agora (disponíveis e sem quarentena ativa).
  def available_for_checkin
    @scope.available_for_checkin.order(:number)
  end

  # Quartos que ficarão disponíveis nos próximos X minutos.
  def becoming_available_within(minutes = 30)
    @scope.becoming_available_within(minutes).order(:quarantine_until)
  end

  # Quartos aptos a receber uma nova comanda:
  # disponíveis ou ocupados e que ainda não possuem comanda aberta.
  def eligible_for_new_tab
    @scope.where(status: [ :available, :occupied ]).order(:number).reject(&:has_open_tab?)
  end
end
