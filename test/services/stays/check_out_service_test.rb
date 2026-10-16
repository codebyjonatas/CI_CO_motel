require "test_helper"

class Stays::CheckOutServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @stay = stays(:one)
    @room = @stay.room
    @room.update!(status: :occupied)
    @product = Product.create!(code: "CHECKOUT1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "completes the stay, sets room to dirty and starts a cleaning log" do
    result = Stays::CheckOutService.call(stay: @stay, user: @user)

    assert result.success?

    @stay.reload
    assert_equal "completed", @stay.status
    assert_not_nil @stay.check_out

    assert_equal "dirty", @room.reload.status

    log = @room.cleaning_logs.last
    assert_not_nil log
    assert_equal "started", log.status
    assert_equal @user, log.cleaned_by
  end

  test "closes open tabs of the stay on check-out" do
    tab = Tab.create!(room: @room, stay: @stay, opened_by: @user)
    tab.tab_items.create!(product: @product, added_by: @user, quantity: 2, unit_price: @product.price)
    tab.recalculate_totals!

    result = Stays::CheckOutService.call(stay: @stay, user: @user)

    assert result.success?
    assert_equal "closed", tab.reload.status
  end

  test "fails when the stay is not active" do
    @stay.update!(status: :completed, check_out: Time.current)

    result = Stays::CheckOutService.call(stay: @stay, user: @user)

    assert result.failure?
    # o quarto não deve ser alterado quando o check-out falha
    assert_equal "occupied", @room.reload.status
  end
end
