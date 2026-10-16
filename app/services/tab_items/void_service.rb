module TabItems
  class VoidService < ApplicationService
    def initialize(tab_item:, user:, reason:)
      @tab_item = tab_item
      @user = user
      @reason = reason
    end

    def call
      return failure("Item já estornado") if @tab_item.voided?
      return failure("Comanda não permite estorno (status: #{@tab_item.tab.status})") unless @tab_item.tab.open? || @tab_item.tab.closed?
      return failure("Motivo é obrigatório") if @reason.blank?

      Tab.transaction do
        @tab_item.void!(user: @user, reason: @reason)

        RoomStatusLog.create!(
          room: @tab_item.tab.room,
          stay: @tab_item.tab.stay,
          user: @user,
          from_status: @tab_item.tab.room.status,
          to_status: @tab_item.tab.room.status,
          trigger: :manual,
          notes: "Item estornado: #{@tab_item.product.name} x#{@tab_item.quantity} (R$ #{@tab_item.total_price}) - Motivo: #{@reason}"
        )

        success(@tab_item)
      end
    end
  end
end
