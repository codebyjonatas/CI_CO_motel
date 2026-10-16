require "test_helper"

class TabReportQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @room = rooms(:one)
    @product = Product.create!(code: "REPORT1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "aggregates revenue from paid tabs" do
    pay_tab(quantity: 2)

    report = TabReportQuery.new.call

    assert_equal 20.0, report[:total_revenue]
    assert_equal 1, report[:paid_tabs_count]
    assert_equal 20.0, report[:average_ticket]
    assert_equal 20.0, report[:revenue_by_room][@room.number]
    assert_equal 20.0, report[:revenue_by_attendant]["Admin User"]
    assert_equal 20.0, report[:top_products]["Cerveja"]
    assert_equal 1, report[:revenue_by_day].size
  end

  test "does not count open or closed tabs as revenue" do
    open_tab(quantity: 3)
    closed_tab(quantity: 1)

    report = TabReportQuery.new.call

    assert_equal 0.0, report[:total_revenue]
    assert_equal 0, report[:paid_tabs_count]
    assert_equal 40.0, report[:open_value] + report[:closed_value]
  end

  test "filters revenue by period" do
    recent = pay_tab(quantity: 1)
    old = pay_tab(quantity: 5)
    old.update_column(:paid_at, 10.days.ago)

    report = TabReportQuery.new(date_from: 5.days.ago.to_date.to_s).call

    assert_equal 10.0, report[:total_revenue]
    assert_equal 1, report[:paid_tabs_count]
    assert_equal recent.id, Tab.where(status: :paid).where("paid_at >= ?", 5.days.ago).first.id
  end

  private

  def build_tab(quantity:)
    tab = Tab.create!(room: @room, opened_by: @user, guest_identifier: "Cliente")
    tab.tab_items.create!(product: @product, added_by: @user, quantity: quantity, unit_price: @product.price)
    tab.recalculate_totals!
    tab
  end

  def pay_tab(quantity:)
    tab = build_tab(quantity: quantity)
    tab.pay!(user: @user)
    tab
  end

  def open_tab(quantity:)
    build_tab(quantity: quantity)
  end

  def closed_tab(quantity:)
    tab = build_tab(quantity: quantity)
    tab.close!(user: @user)
    tab
  end
end
