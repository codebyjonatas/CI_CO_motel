module Stays
  # Finaliza uma estadia: fecha as comandas abertas, marca a estadia como
  # concluída e coloca o quarto no ciclo de limpeza (dirty + CleaningLog).
  class CheckOutService < ApplicationService
    def initialize(stay:, user:, notes: nil)
      @stay = stay
      @user = user
      @notes = notes
    end

    def call
      return failure("Estadia já finalizada (status: #{@stay.status})") unless @stay.active?

      error = nil

      # Fechamento de comandas + conclusão da estadia na mesma transação:
      # se o quarto/log falhar, nenhuma comanda fica fechada pela metade.
      Stay.transaction do
        account = CloseAccountService.call(stay: @stay, user: @user, notes: @notes)

        unless account.success?
          error = account.error
          raise ActiveRecord::Rollback
        end

        @stay.update!(check_out: Time.current, status: :completed)
        release_room
      end

      return failure(error) if error

      success(@stay)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def release_room
      room = @stay.room
      room.check_out! if room.may_check_out?
      return unless room.dirty?

      CleaningLog.create!(
        room: room,
        stay: @stay,
        cleaned_by: @user,
        started_at: Time.current,
        status: :started,
        notes: "Limpeza pendente após check-out da estadia ##{@stay.id}"
      )
    end
  end
end
