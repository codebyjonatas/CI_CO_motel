module TabItems
  class AddItemService < ApplicationService
    ConcurrencyError = Class.new(StandardError)

    def initialize(tab:, product:, quantity:, added_by:, unit_price: nil, notes: nil)
      @tab = tab
      @product = product
      @quantity = quantity.to_i
      @added_by = added_by
      @unit_price = unit_price&.to_d || @product.current_price
      @notes = notes
    end

    def call
      return failure("Comanda não aceita mais itens (status: #{@tab.status})") unless @tab.can_add_items?
      return failure("Produto inativo") unless @product.active?
      return failure("Quantidade deve ser maior que zero") if @quantity <= 0

      @tab.with_lock do
        # Re-valida dentro do lock para evitar race condition
        return failure("Comanda foi fechada por outro processo") unless @tab.can_add_items?

        item = @tab.tab_items.create!(
          product: @product,
          added_by: @added_by,
          quantity: @quantity,
          unit_price: @unit_price,
          total_price: @quantity * @unit_price,
          notes: @notes,
          status: :active
        )

        @tab.recalculate_totals!

        success(item)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
