class TabsController < ApplicationController
  before_action :set_room, only: [ :index, :new, :create, :create_walk_in ]
  before_action :set_tab, only: [ :show, :close, :pay, :cancel, :transfer, :apply_discount ]
  before_action :authorize_tab, except: [ :index, :new, :create, :create_walk_in, :dashboard, :report ]

  def index
    @tabs = policy_scope(Tab).for_room(@room).ordered
    @active_tab = @room.current_tab
  end

  def dashboard
    authorize Tab, :index?
    @query = TabDashboardQuery.new(params)
    @tabs = @query.call
    @summary = @query.summary
    @rooms = Room.order(:number)
    @eligible_rooms = AvailableRoomsQuery.new.eligible_for_new_tab
  end

  def report
    authorize Tab, :index?
    @report = TabReportQuery.new(params).call
    @rooms = Room.order(:number)
  end

  def show
    @tab_items = @tab.tab_items.includes(:product, :added_by, :voided_by).ordered
  end

  def new
    @walk_in = params[:walk_in].present?
    @tab = @room.tabs.build
    @stays = @room.stays.active_stays
    authorize @tab
  end

  def create
    stay = params[:stay_id].present? ? Stay.find(params[:stay_id]) : nil

    @tab = Tabs::CreateService.call(
      room: @room,
      opened_by: current_user,
      guest_identifier: params[:guest_identifier],
      stay: stay,
      notes: params[:notes]
    )

    if @tab.success?
      redirect_to room_tab_path(@room, @tab.data), notice: "Comanda aberta com sucesso"
    else
      @stays = @room.stays.active_stays
      flash.now[:alert] = @tab.error
      render :new, status: :unprocessable_entity
    end
  end

  def create_walk_in
    @tab = Tabs::CreateWalkInService.call(
      room: @room,
      guest_identifier: params[:guest_identifier],
      opened_by: current_user,
      notes: params[:notes]
    )

    if @tab.success?
      redirect_to room_tab_path(@room, @tab.data), notice: "Comanda passante aberta com sucesso"
    else
      flash.now[:alert] = @tab.error
      render :new, status: :unprocessable_entity
    end
  end

  def close
    result = Tabs::CloseService.call(tab: @tab, user: current_user, notes: params[:notes])

    if result.success?
      redirect_to room_tabs_path(@tab.room), notice: "Comanda fechada com sucesso"
    else
      redirect_to room_tab_path(@tab.room, @tab), alert: result.error
    end
  end

  def pay
    result = Tabs::PayService.call(tab: @tab, user: current_user, notes: params[:notes])

    if result.success?
      redirect_to room_tabs_path(@tab.room), notice: "Comanda paga com sucesso"
    else
      redirect_to room_tab_path(@tab.room, @tab), alert: result.error
    end
  end

  def cancel
    result = Tabs::CancelService.call(tab: @tab, user: current_user, reason: params[:reason])

    if result.success?
      redirect_to room_tabs_path(@tab.room), notice: "Comanda cancelada com sucesso"
    else
      redirect_to room_tab_path(@tab.room, @tab), alert: result.error
    end
  end

  def transfer
    target_room = Room.find(params[:target_room_id])
    target_stay = params[:target_stay_id].present? ? Stay.find(params[:target_stay_id]) : nil

    result = Tabs::TransferService.call(
      source_tab: @tab,
      target_room: target_room,
      target_stay: target_stay,
      user: current_user,
      notes: params[:notes]
    )

    if result.success?
      redirect_to room_tab_path(target_room, result.data), notice: "Comanda transferida com sucesso"
    else
      redirect_to room_tab_path(@tab.room, @tab), alert: result.error
    end
  end

  def apply_discount
    percent = params[:percent].to_f
    absolute = params[:absolute].to_f

    @tab.apply_discount!(user: current_user, percent: percent, absolute: absolute)

    respond_to do |format|
      format.html { redirect_to room_tab_path(@tab.room, @tab), notice: "Desconto aplicado" }
      format.json { render json: { total: @tab.total, discount: @tab.discount } }
    end
  rescue DiscountLimit::LimitExceeded => e
    respond_to do |format|
      format.html { redirect_to room_tab_path(@tab.room, @tab), alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_tab
    @tab = Tab.find(params[:id])
  end

  def authorize_tab
    authorize @tab
  end
end
