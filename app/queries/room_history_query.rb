# Monta a linha do tempo unificada de um quarto, combinando estadias,
# comandas, limpezas e mudanças de status em uma única coleção ordenada.
class RoomHistoryQuery
  Event = Struct.new(:at, :category, :title, :description, :badge, keyword_init: true)

  def initialize(room)
    @room = room
  end

  def call
    events.compact.sort_by { |event| event.at || Time.at(0) }.reverse
  end

  private

  def events
    stay_events + tab_events + cleaning_events + status_events
  end

  def stay_events
    @room.stays.flat_map do |stay|
      list = [
        Event.new(
          at: stay.check_in,
          category: :stay,
          title: "Check-in - Estadia ##{stay.id}",
          description: "Hóspede: #{stay.user&.name}",
          badge: "badge-primary"
        )
      ]

      unless stay.check_out.nil?
        list << Event.new(
          at: stay.check_out,
          category: :stay,
          title: "Check-out - Estadia ##{stay.id}",
          description: "Total: #{stay.total_value}",
          badge: "badge-success"
        )
      end

      list
    end
  end

  def tab_events
    @room.tabs.flat_map do |tab|
      list = [
        Event.new(
          at: tab.created_at,
          category: :tab,
          title: "Comanda ##{tab.id} aberta",
          description: tab.guest_identifier,
          badge: "badge-accent"
        )
      ]

      unless tab.closed_at.nil?
        list << Event.new(
          at: tab.closed_at,
          category: :tab,
          title: "Comanda ##{tab.id} fechada",
          description: "Total: #{tab.total}",
          badge: "bg-warning text-dark"
        )
      end

      unless tab.paid_at.nil?
        list << Event.new(
          at: tab.paid_at,
          category: :tab,
          title: "Comanda ##{tab.id} paga",
          description: "Total: #{tab.total}",
          badge: "bg-dark text-white"
        )
      end

      list
    end
  end

  def cleaning_events
    @room.cleaning_logs.flat_map do |log|
      list = [
        Event.new(
          at: log.started_at || log.created_at,
          category: :cleaning,
          title: "Limpeza pendente/iniciada",
          description: log.cleaned_by&.name,
          badge: "bg-danger text-white"
        )
      ]

      unless log.finished_at.nil?
        list << Event.new(
          at: log.finished_at,
          category: :cleaning,
          title: "Limpeza finalizada",
          description: log.cleaned_by&.name,
          badge: "bg-info text-dark"
        )
      end

      unless log.inspected_at.nil?
        list << Event.new(
          at: log.inspected_at,
          category: :cleaning,
          title: log.approved? ? "Inspeção aprovada" : "Inspeção rejeitada",
          description: log.rejection_reason.presence || log.inspected_by&.name,
          badge: log.approved? ? "badge-success" : "bg-danger text-white"
        )
      end

      list
    end
  end

  def status_events
    @room.room_status_logs.map do |log|
      Event.new(
        at: log.created_at,
        category: :status,
        title: "#{log.from_status&.humanize} → #{log.to_status&.humanize}",
        description: log.notes,
        badge: "bg-secondary text-white"
      )
    end
  end
end
