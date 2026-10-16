# Relatórios de faturamento do bar a partir das comandas pagas.
# Aceita filtros opcionais de período (date_from/date_to).
class TabReportQuery
  def initialize(params = {})
    @params = params
  end

  def call
    {
      date_from: date_from,
      date_to: date_to,
      total_revenue: paid_scope.sum(:total).to_f,
      paid_tabs_count: paid_scope.count,
      average_ticket: average_ticket,
      open_value: Tab.where(status: :open).sum(:total).to_f,
      closed_value: Tab.where(status: :closed).sum(:total).to_f,
      revenue_by_day: revenue_by_day,
      revenue_by_room: revenue_by_room,
      revenue_by_attendant: revenue_by_attendant,
      top_products: top_products
    }
  end

  private

  def paid_scope
    @paid_scope ||= begin
      scope = Tab.where(status: :paid)
      scope = scope.where("tabs.paid_at >= ?", date_from.beginning_of_day) if date_from
      scope = scope.where("tabs.paid_at <= ?", date_to.end_of_day) if date_to
      scope
    end
  end

  def average_ticket
    count = paid_scope.count
    return 0.0 if count.zero?

    (paid_scope.sum(:total) / count.to_f).round(2)
  end

  def revenue_by_day
    paid_scope.group(Arel.sql("DATE(tabs.paid_at)")).sum(:total)
  end

  def revenue_by_room
    paid_scope.joins(:room).group("rooms.number").sum(:total)
  end

  def revenue_by_attendant
    paid_scope.joins(:opened_by).group("users.name").sum(:total)
  end

  def top_products
    TabItem.where(status: :active)
           .where(tab_id: paid_scope.select(:id))
           .joins(:product)
           .group("products.name")
           .order(Arel.sql("SUM(tab_items.total_price) DESC"))
           .limit(10)
           .pluck(Arel.sql("products.name"), Arel.sql("SUM(tab_items.total_price)"))
           .to_h
  end

  def date_from
    @date_from ||= parse_date(@params[:date_from])
  end

  def date_to
    @date_to ||= parse_date(@params[:date_to])
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
