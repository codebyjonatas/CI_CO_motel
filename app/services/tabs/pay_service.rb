module Tabs
  class PayService < ApplicationService
    def initialize(tab:, user:, notes: nil)
      @tab = tab
      @user = user
      @notes = notes
    end

    def call
      return failure("Comanda não pode ser paga (status: #{@tab.status})") unless @tab.closed? || @tab.open?
      return failure("Comanda não possui itens") if @tab.active_items.empty?

      Tab.transaction do
        @tab.close!(user: @user, notes: @notes) if @tab.open?
        @tab.pay!(user: @user, notes: @notes)

        RoomStatusLog.create!(
          room: @tab.room,
          stay: @tab.stay,
          user: @user,
          from_status: @tab.room.status,
          to_status: @tab.room.status,
          trigger: :manual,
          notes: "Comanda ##{@tab.id} paga. Total: R$ #{@tab.total}"
        )

        success(@tab)
      end
    end
  end
end
