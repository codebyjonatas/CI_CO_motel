require "test_helper"

class Stays::CancelServiceTest < ActiveSupport::TestCase
  setup do
    # Horário fixo: o check-in de 1h só é válido fora da janela 22h-6h.
    travel_to Time.zone.local(2026, 1, 5, 15, 0, 0)

    @user = users(:admin)
    @stay = stays(:one)
    @room = @stay.room
    @room.update!(status: :occupied)
    @product = Product.create!(code: "CANCEL1", name: "Cerveja", category: :beer, price: 10.0)
  end

  teardown { travel_back }

  test "cancels active stays, their tabs and releases the room" do
    tab = build_tab

    result = Stays::CancelService.call(stay: @stay, user: @user, reason: "Cliente desistiu")

    assert result.success?
    assert_equal "cancelled", @stay.reload.status
    assert_equal "available", @room.reload.status
    assert_equal "cancelled", tab.reload.status
    assert_equal "Cliente desistiu", tab.notes
    assert_equal "cancel", @room.room_status_logs.last.trigger
  end

  test "does not cancel a stay that is already completed" do
    @stay.update!(status: :completed, check_out: Time.current)

    result = Stays::CancelService.call(stay: @stay, user: @user)

    assert result.failure?
    assert_equal "completed", @stay.reload.status
    assert_equal "occupied", @room.reload.status
  end

  test "keeps the room occupied when another active stay exists" do
    other = Stay.create!(
      room: @room,
      user: @user,
      price_period_id: 1,
      check_in: 1.hour.ago,
      total_value: 18
    )

    result = Stays::CancelService.call(stay: @stay, user: @user)

    assert result.success?
    assert_equal "cancelled", @stay.reload.status
    assert_equal "active", other.reload.status
    assert_equal "occupied", @room.reload.status
  end

  private

  def build_tab
    tab = Tab.create!(room: @room, stay: @stay, opened_by: @user)
    tab.tab_items.create!(
      product: @product,
      added_by: @user,
      quantity: 2,
      unit_price: @product.price
    )
    tab.recalculate_totals!
    tab
  end
end
