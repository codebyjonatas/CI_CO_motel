require "application_system_test_case"

class StayCheckOutTest < ApplicationSystemTestCase
  test "finalizar check-out conclui a estadia e envia o quarto para limpeza" do
    room = rooms(:one)
    stay = stays(:one)
    room.update!(status: :occupied)

    sign_in_as(users(:admin))

    visit stay_path(stay)
    click_on "Finalizar Check-out", match: :first

    assert_text "Check-out realizado com sucesso."

    stay.reload
    assert stay.completed?, "esperava estadia com status completed"
    assert_not_nil stay.check_out

    room.reload
    assert room.status_dirty?, "esperava quarto sujo (dirty) após o check-out"
    assert room.cleaning_logs.where(status: :started).exists?,
           "esperava um CleaningLog iniciado no check-out"
  end
end
