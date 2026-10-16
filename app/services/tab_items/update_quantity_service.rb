module TabItems
  class UpdateQuantityService < ApplicationService
    def initialize(tab_item:, user:, quantity:, reason: nil)
      @tab_item = tab_item
      @user = user
      @quantity = quantity.to_i
      @reason = reason
    end

    def call
      return failure("Item não está ativo") unless @tab_item.active?
      return failure("Comanda não permite alteração (status: #{@tab_item.tab.status})") unless @tab_item.tab.open?
      return failure("Quantidade deve ser maior que zero") if @quantity <= 0

      Tab.transaction do
        previous_qty = @tab_item.quantity

        @tab_item.audits.create!(
          action: :quantity_change,
          user: @user,
          reason: @reason || "Alteração de quantidade",
          previous_state: { "quantity" => previous_qty },
          tab_status_at_time: @tab_item.tab.status_before_type_cast
        )

        @tab_item.update!(quantity: @quantity, total_price: @quantity * @tab_item.unit_price)
        @tab_item.tab.recalculate_totals!

        success(@tab_item)
      end
    end
  end
end
