require "test_helper"

class Stays::CloseAccountServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @stay = stays(:one)
    @product = Product.create!(code: "CLOSE1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "closes open tabs that have items" do
    tab = build_tab(quantity: 2)

    result = Stays::CloseAccountService.call(stay: @stay, user: @user)

    assert result.success?
    assert_equal "closed", tab.reload.status
    assert_equal "closed", tab.status
    assert_includes result.data[:closed], tab
    assert_empty result.data[:cancelled]
  end

  test "cancels open tabs without items" do
    empty = Tab.create!(room: @stay.room, stay: @stay, opened_by: @user)

    result = Stays::CloseAccountService.call(stay: @stay, user: @user)

    assert result.success?
    assert_equal "cancelled", empty.reload.status
    assert_includes result.data[:cancelled], empty
    assert_empty result.data[:closed]
  end

  test "does nothing when there are no open tabs" do
    result = Stays::CloseAccountService.call(stay: @stay, user: @user)

    assert result.success?
    assert_empty result.data[:closed]
    assert_empty result.data[:cancelled]
  end

  private

  def build_tab(quantity:)
    tab = Tab.create!(room: @stay.room, stay: @stay, opened_by: @user)
    tab.tab_items.create!(product: @product, added_by: @user, quantity: quantity, unit_price: @product.price)
    tab.recalculate_totals!
    tab
  end
end
