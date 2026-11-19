module Stays
  # Cancela uma estadia ativa de forma atômica:
  # - cancela comandas abertas/fechadas (não deixa consumo pendurado);
  # - marca a estadia como cancelled;
  # - devolve o quarto para available, desde que não haja outra estadia ativa.
  class CancelService < ApplicationService
    DEFAULT_REASON = "Cancelamento de estadia".freeze

    def initialize(stay:, user:, reason: nil)
      @stay = stay
      @user = user
      @reason = reason
    end

    def call
      return failure("Apenas estadias ativas podem ser canceladas (status: #{@stay.status})") unless @stay.active?

      reason = @reason.presence || DEFAULT_REASON

      Stay.transaction do
        cancel_tabs(reason)
        @stay.update!(status: :cancelled)
        release_room
      end

      success(@stay)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def cancel_tabs(reason)
      @stay.tabs.where(status: [ :open, :closed ]).find_each do |tab|
        tab.cancel!(user: @user, reason: reason)
      end
    end

    def release_room
      room = @stay.room
      return unless room&.status_occupied?
      return if room.stays.active_stays.where.not(id: @stay.id).exists?

      # Informa o motivo real da transição para o RoomAuditable.
      Current.room_status_trigger = :cancel
      begin
        room.update!(status: :available)
      ensure
        Current.room_status_trigger = nil
      end
    end
  end
end
