require "test_helper"

class StaysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @stay = stays(:one)
    @room = @stay.room
    @room.update!(status: :occupied)
    @product = Product.create!(code: "STAYSAUTH1", name: "Cerveja", category: :beer, price: 10.0)
  end

  test "index requires authentication" do
    get stays_url

    assert_redirected_to new_user_session_url
  end

  test "attendant cannot change stay status or total value" do
    sign_in users(:attendant)
    original_total = @stay.total_value

    patch stay_url(@stay), params: {
      stay: { status: "completed", total_value: "9999.99", observation: "Observação do atendente" }
    }

    assert_redirected_to stay_url(@stay)

    @stay.reload
    assert @stay.active?
    assert_equal original_total, @stay.total_value
    assert_equal "Observação do atendente", @stay.observation
  end

  test "admin can update the stay total value" do
    sign_in users(:admin)

    patch stay_url(@stay), params: { stay: { total_value: "123.45" } }

    assert_redirected_to stay_url(@stay)
    assert_equal "123.45", @stay.reload.total_value.to_s("F")
  end

  test "cancel cancels open tabs and frees the room" do
    sign_in users(:admin)
    tab = Tab.create!(room: @room, stay: @stay, opened_by: users(:admin))
    tab.tab_items.create!(product: @product, added_by: users(:admin), quantity: 1, unit_price: @product.price)

    patch cancel_stay_url(@stay)

    assert_redirected_to stays_url
    assert @stay.reload.cancelled?
    assert_equal "available", @room.reload.status
    assert_equal "cancelled", tab.reload.status
  end

  test "cancel is rejected for a completed stay" do
    sign_in users(:admin)
    @stay.update!(status: :completed, check_out: Time.current)

    patch cancel_stay_url(@stay)

    assert_redirected_to stay_url(@stay)
    assert @stay.reload.completed?
    assert_match(/Apenas estadias ativas/, flash[:alert])
    assert_equal "occupied", @room.reload.status
  end

  test "destroy with linked tabs redirects with an error instead of raising" do
    sign_in users(:admin)
    Tab.create!(room: @room, stay: @stay, opened_by: users(:admin))

    delete stay_url(@stay)

    assert_redirected_to stay_url(@stay)
    assert flash[:alert].present?
    assert Stay.exists?(@stay.id)
  end
end
