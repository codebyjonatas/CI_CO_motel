require "test_helper"

class TabDashboardQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @room = rooms(:one)
    @product = Product.create!(code: "DASH1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "summary soma o valor das comandas sem multiplicar pelo número de itens" do
    tab = build_tab(quantities: [ 1, 1, 3 ])

    summary = TabDashboardQuery.new.summary

    assert_equal 50.0, summary[:total_pending_value]
    assert_equal 1, summary[:open]
    assert_equal 50.0, summary[:by_room][@room.number]
  end

  test "summary considera somente comandas pagas hoje no recebido" do
    tab = build_tab(quantities: [ 2 ])
    tab.close!(user: @user)
    tab.pay!(user: @user)

    summary = TabDashboardQuery.new.summary

    assert_equal 20.0, summary[:total_paid_today]
    assert_equal 0.0, summary[:total_pending_value]
  end

  private

  def build_tab(quantities:)
    tab = Tab.create!(room: @room, opened_by: @user, guest_identifier: "Cliente")
    quantities.each do |quantity|
      tab.tab_items.create!(product: @product, added_by: @user, quantity: quantity, unit_price: @product.price)
    end
    tab.recalculate_totals!
    tab
  end
end
