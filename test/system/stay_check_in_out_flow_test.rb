require "application_system_test_case"

class StayCheckInOutFlowTest < ApplicationSystemTestCase
  test "fluxo completo: check-in -> check-out (atendente)" do
    room = rooms(:one)
    attendant = users(:attendant)

    # Garante que o quarto está disponível
    room.update!(status: :available)

    # 1. Login como atendente
    sign_in_as(attendant)

    # 2. Acessa página de novo check-in
    visit new_stay_path

    # 3. Preenche o formulário de check-in
    select room.number, from: "Selecione o quarto"
    choose "1 Hora"
    fill_in "Data e hora do check-in", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    fill_in "Observações (opcional)", with: "Teste fluxo completo check-in/check-out"
    fill_in "Confirme sua senha", with: "123456"

    # 4. Submete o check-in
    click_button "Confirmar Check-in"

    # 5. Verifica sucesso do check-in
    assert_text "Check-in realizado com sucesso."
    assert_text room.number
    assert_text "1 Hora"
    assert_text "Em andamento"

    # Obtém a estadia criada
    stay = Stay.last
    assert stay.active?
    assert stay.room == room

    # 6. Verifica que o quarto ficou ocupado
    room.reload
    assert room.status_occupied?, "Quarto deveria estar ocupado após check-in"

    # 7. Acessa a página da estadia (show)
    visit stay_path(stay)

    # 8. Realiza check-out (POST direto pois rack_test não suporta confirm modal)
    page.driver.submit :patch, check_out_stay_path(stay), {}

    # 9. Verifica sucesso do check-out
    assert_text "Check-out realizado com sucesso."
    assert_text "Finalizada"

    # 10. Verifica estado final
    stay.reload
    assert stay.completed?, "Estadia deveria estar finalizada"
    assert_not_nil stay.check_out

    room.reload
    assert room.status_dirty?, "Quarto deveria estar sujo (dirty) após check-out"
    assert room.cleaning_logs.where(status: :started).exists?,
           "Deveria ter CleaningLog iniciado"
  end

  test "fluxo completo: check-in -> check-out (admin)" do
    room = rooms(:two)
    admin = users(:admin)

    room.update!(status: :available)

    sign_in_as(admin)

    visit new_stay_path

    select room.number, from: "Selecione o quarto"
    choose "2 Horas"
    fill_in "Data e hora do check-in", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    fill_in "Confirme sua senha", with: "123456"

    click_button "Confirmar Check-in"

    assert_text "Check-in realizado com sucesso."

    stay = Stay.last
    assert stay.active?

    room.reload
    assert room.status_occupied?

    visit stay_path(stay)

    page.driver.submit :patch, check_out_stay_path(stay), {}

    assert_text "Check-out realizado com sucesso."

    stay.reload
    assert stay.completed?
    assert_not_nil stay.check_out

    room.reload
    assert room.status_dirty?
    assert room.cleaning_logs.where(status: :started).exists?
  end

  test "check-in falha com senha incorreta" do
    room = rooms(:three)
    attendant = users(:attendant)

    room.update!(status: :available)

    sign_in_as(attendant)

    visit new_stay_path

    select room.number, from: "Selecione o quarto"
    choose "1 Hora"
    fill_in "Data e hora do check-in", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    fill_in "Confirme sua senha", with: "senha_errada"

    click_button "Confirmar Check-in"

    assert_text "Senha incorreta"
    assert_no_text "Check-in realizado com sucesso"

    room.reload
    assert room.status_available?, "Quarto deveria continuar disponível"
  end

  test "check-in não mostra quartos indisponíveis" do
    room = rooms(:one)
    attendant = users(:attendant)

    # Quarto ocupado
    room.update!(status: :occupied)

    sign_in_as(attendant)

    visit new_stay_path

    # O quarto não deveria aparecer no select
    refute page.has_select?("Selecione o quarto", with_options: [ room.number ])
  end
end
