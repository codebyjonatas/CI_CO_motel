require "test_helper"

class TabTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @source_room = rooms(:one)
    @target_room = rooms(:two)
    @product = Product.create!(code: "TABTEST1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "transfer_to! moves items and recalculates destination totals" do
    source = build_tab(items: [ { quantity: 2 } ])

    new_tab = source.transfer_to!(target_room: @target_room, target_stay: nil, user: @user)

    assert_equal "open", new_tab.reload.status
    assert_equal @target_room, new_tab.room
    assert_equal 1, new_tab.active_items.count
    assert_equal 20.0, new_tab.subtotal.to_f
    assert_equal 20.0, new_tab.total.to_f
  end

  test "transfer_to! clears source totals and marks items as transferred" do
    source = build_tab(items: [ { quantity: 1 }, { quantity: 3 } ])

    source.transfer_to!(target_room: @target_room, target_stay: nil, user: @user)
    source.reload

    assert_equal "transferred", source.status
    assert_equal 0, source.active_items.count
    assert_equal 0.0, source.subtotal.to_f
    assert_equal 0.0, source.discount.to_f
    assert_equal 0.0, source.total.to_f
  end

  private

  def build_tab(items:)
    tab = Tab.create!(room: @source_room, opened_by: @user, guest_identifier: "João Silva")
    items.each do |attrs|
      tab.tab_items.create!(
        product: @product,
        added_by: @user,
        quantity: attrs[:quantity],
        unit_price: @product.price
      )
    end
    tab.recalculate_totals!
    tab
  end
end
