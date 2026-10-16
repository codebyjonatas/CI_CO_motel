require "application_system_test_case"

class RoomCleaningCycleTest < ApplicationSystemTestCase
  test "ciclo de limpeza: dirty -> cleaning -> quarantine -> available" do
    room = rooms(:one)
    room.update!(status: :dirty)

    sign_in_as(users(:attendant))

    visit room_path(room)
    click_on "Iniciar Limpeza"
    assert_text "Limpeza iniciada."
    assert room.reload.status_cleaning?

    click_on "Finalizar Limpeza"
    assert_text "Limpeza finalizada."
    room.reload
    assert room.status_quarantine?
    assert room.quarantine_until > Time.current, "quarentena deve estar no futuro"

    travel 31.minutes do
      visit room_path(room)
      click_on "Liberar da Quarentena"
      assert_text "Quarto liberado para uso."
    end

    room.reload
    assert room.status_available?, "esperava quarto disponível após a quarentena"
    assert room.cleaning_logs.where(status: :approved).exists?,
           "esperava CleaningLog aprovado após liberar a quarentena"
  end
end
