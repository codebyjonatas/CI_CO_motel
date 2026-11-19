class TabsController < ApplicationController
  before_action :set_room, only: [ :index, :new, :create, :create_walk_in, :show, :close, :pay, :cancel, :transfer, :apply_discount ]
  before_action :set_tab, only: [ :show, :close, :pay, :cancel, :transfer, :apply_discount ]
  before_action :set_current_room, only: [ :index, :new, :create, :create_walk_in, :show, :close, :pay, :cancel, :transfer, :apply_discount ]
  before_action :authorize_tab, only: [ :show, :close, :pay, :cancel, :transfer, :apply_discount ]
  before_action :authorize_tab_creation, only: [ :create, :create_walk_in ]

  after_action :verify_policy_scoped, only: :index, unless: :skip_authorization_verification?

  def index
    authorize @room, :show?
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
    stay = @room.stays.active_stays.find(params[:stay_id]) if params[:stay_id].present?

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
    authorize target_room, :show?
    target_stay = target_room.stays.active_stays.find(params[:target_stay_id]) if params[:target_stay_id].present?

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
    # A comanda precisa pertencer ao quarto informado na URL (evita IDOR).
    @tab = @room.tabs.find(params[:id])
  end

  def set_current_room
    Current.room = @room
  end

  def authorize_tab
    authorize @tab
  end

  def authorize_tab_creation
    authorize Tab
  end
end
