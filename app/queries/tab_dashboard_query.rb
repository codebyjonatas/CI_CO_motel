class TabDashboardQuery
  def initialize(params = {})
    @params = params
  end

  def call
    scope = base_scope
    scope = apply_filters(scope)
    scope = apply_order(scope)
    scope.page(@params[:page]).per(@params[:per_page] || 20)
  end

  def summary
    # Agregações usam Tab.all: o `includes(:active_items)` do escopo da listagem
    # vira JOIN e multiplica o total pelo número de itens de cada comanda.
    base = Tab.all
    {
      open: base.where(status: :open).count,
      closed: base.where(status: :closed).count,
      paid: base.where(status: :paid).count,
      cancelled: base.where(status: :cancelled).count,
      transferred: base.where(status: :transferred).count,
      total_pending_value: base.where(status: [ :open, :closed ]).sum(:total),
      total_paid_today: base.where(status: :paid, paid_at: Time.current.all_day).sum(:total),
      by_room: base.where(status: [ :open, :closed ])
                   .joins(:room)
                   .group("rooms.number")
                   .sum(:total),
      by_attendant: base.where(status: [ :open, :closed ])
                        .joins(:opened_by)
                        .group("users.name")
                        .sum(:total)
    }
  end

  private

  def base_scope
    Tab.includes(:room, :stay, :opened_by, :closed_by, :active_items)
  end

  def apply_filters(scope)
    scope = scope.where(status: @params[:status]) if @params[:status].present?
    scope = scope.where(room_id: @params[:room_id]) if @params[:room_id].present?
    scope = scope.where("created_at >= ?", @params[:date_from]) if @params[:date_from].present?
    scope = scope.where("created_at <= ?", @params[:date_to]) if @params[:date_to].present?
    scope = scope.where(stay_id: nil) if @params[:walk_in_only] == "true"
    scope = scope.where.not(stay_id: nil) if @params[:stay_only] == "true"
    scope
  end

  def apply_order(scope)
    case @params[:sort]
    when "total_desc" then scope.order(total: :desc)
    when "total_asc" then scope.order(total: :asc)
    when "room" then scope.joins(:room).order("rooms.number")
    else scope.order(created_at: :desc)
    end
  end
end
