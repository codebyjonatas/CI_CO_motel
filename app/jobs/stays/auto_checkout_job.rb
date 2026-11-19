class Stays::AutoCheckoutJob < ApplicationJob
  queue_as :default

  # Encontra estadias ativas que ultrapassaram o tempo do período
  # e realiza check-out automático.
  def perform
    # Carrega estadias ativas com associações necessárias
    active_stays = Stay.active_stays.includes(:room, :user)

    # Filtra em Ruby usando PricePeriodConfig (evita join em tabela removida)
    overdue_stays = active_stays.select do |stay|
      duration = stay.price_period_duration_minutes
      duration > 0 && (stay.check_in + duration.minutes < Time.current)
    end

    Rails.logger.info "[AutoCheckoutJob] Encontradas #{overdue_stays.count} estadias com tempo excedido"

    overdue_stays.each do |stay|
      begin
        auto_checkout_stay(stay)
      rescue => e
        Rails.logger.error "[AutoCheckoutJob] Falha no check-out automático da estadia ##{stay.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  private

  def auto_checkout_stay(stay)
    # Busca um usuário de sistema para executar o check-out
    # (pode ser o próprio atendente da estadia ou um usuário "system")
    user = stay.user || User.system_user

    result = Stays::CheckOutService.call(stay: stay, user: user, notes: "Check-out automático por tempo excedido")

    if result.success?
      Rails.logger.info "[AutoCheckoutJob] Check-out automático realizado: estadia ##{stay.id} (quarto #{stay.room.number})"
    else
      Rails.logger.warn "[AutoCheckoutJob] Falha no check-out automático da estadia ##{stay.id}: #{result.error}"
    end
  end
end
