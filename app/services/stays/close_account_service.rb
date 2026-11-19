module Stays
  # Fecha (ou cancela) todas as comandas abertas de uma estadia.
  # Usado no check-out para garantir que nenhuma comanda fique pendurada.
  class CloseAccountService < ApplicationService
    DEFAULT_NOTES = "Fechamento automático no check-out".freeze

    def initialize(stay:, user:, notes: nil)
      @stay = stay
      @user = user
      @notes = notes
    end

    def call
      closed = []
      cancelled = []
      error = nil

      # requires_new garante um savepoint quando chamado dentro da transação
      # do CheckOutService, sem impedir o rollback do fluxo externo.
      Stay.transaction(requires_new: true) do
        @stay.tabs.where(status: :open).each do |tab|
          if tab.active_items.exists?
            result = Tabs::CloseService.call(tab: tab, user: @user, notes: @notes || DEFAULT_NOTES)

            unless result.success?
              error = result.error
              raise ActiveRecord::Rollback
            end

            closed << tab
          else
            tab.cancel!(user: @user, reason: "Comanda sem itens cancelada no check-out")
            cancelled << tab
          end
        end
      end

      return failure(error) if error

      success(closed: closed, cancelled: cancelled)
    end
  end
end
