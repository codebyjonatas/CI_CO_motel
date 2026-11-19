module Stays
  # Realiza o check-in de uma estadia: valida disponibilidade do quarto,
  # cria a estadia e inicia o ciclo de ocupação (AASM check_in!).
  class CheckInService < ApplicationService
    def initialize(stay:, user:, password:)
      @stay = stay
      @user = user
      @password = password
    end

    def call
      return failure("Senha incorreta") unless @user.valid_password?(@password)

      room = @stay.room
      return failure("Quarto não informado") unless room

      # Lock pessimista no quarto para evitar race condition
      room.with_lock do
        # Recarrega o quarto após o lock para ter o estado mais atual
        room.reload
        return failure("Quarto não está disponível para check-in no momento") unless room.can_checkin?

        Stay.transaction do
          @stay.user = @user
          @stay.save!
          room.check_in!
        end
      end

      success(@stay)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
