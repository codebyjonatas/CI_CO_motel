class TabItemsController < ApplicationController
  before_action :set_tab
  before_action :set_tab_item, only: [ :void, :update_quantity ]
  before_action :authorize_tab_item, only: [ :void, :update_quantity ]

  def create
    authorize @tab, :update?

    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    unit_price = params[:unit_price].presence&.to_d

    result = TabItems::AddItemService.call(
      tab: @tab,
      product: product,
      quantity: quantity,
      added_by: current_user,
      unit_price: unit_price,
      notes: params[:notes]
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), notice: "Item adicionado" }
        format.json { render json: result.data, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), alert: result.error }
        format.json { render json: { error: result.error }, status: :unprocessable_entity }
      end
    end
  end

  def void
    result = TabItems::VoidService.call(
      tab_item: @tab_item,
      user: current_user,
      reason: params[:reason]
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), notice: "Item estornado" }
        format.json { render json: result.data }
      end
    else
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), alert: result.error }
        format.json { render json: { error: result.error }, status: :unprocessable_entity }
      end
    end
  end

  def update_quantity
    result = TabItems::UpdateQuantityService.call(
      tab_item: @tab_item,
      user: current_user,
      quantity: params[:quantity],
      reason: params[:reason]
    )

    if result.success?
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), notice: "Quantidade atualizada" }
        format.json { render json: result.data }
      end
    else
      respond_to do |format|
        format.html { redirect_to room_tab_path(@tab.room, @tab), alert: result.error }
        format.json { render json: { error: result.error }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_tab
    # Garante que a comanda pertence ao quarto da URL.
    @room = Room.find(params[:room_id])
    @tab = @room.tabs.find(params[:tab_id])
  end

  def set_tab_item
    @tab_item = @tab.tab_items.find(params[:id])
  end

  def authorize_tab_item
    authorize @tab_item
  end
end
