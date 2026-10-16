module Tabs
  class CancelService < ApplicationService
    def initialize(tab:, user:, reason:)
      @tab = tab
      @user = user
      @reason = reason
    end

    def call
      return failure("Comanda não pode ser cancelada (status: #{@tab.status})") unless @tab.open? || @tab.closed?
      return failure("Motivo é obrigatório") if @reason.blank?

      Tab.transaction do
        @tab.cancel!(user: @user, reason: @reason)

        RoomStatusLog.create!(
          room: @tab.room,
          stay: @tab.stay,
          user: @user,
          from_status: @tab.room.status,
          to_status: @tab.room.status,
          trigger: :manual,
          notes: "Comanda ##{@tab.id} cancelada. Motivo: #{@reason}"
        )

        success(@tab)
      end
    end
  end
end
