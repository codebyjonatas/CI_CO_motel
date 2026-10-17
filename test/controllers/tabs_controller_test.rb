require "test_helper"

class TabsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "dashboard requires authentication" do
    get tabs_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "dashboard renders summary and tab list" do
    sign_in users(:admin)
    Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "João Silva")

    get tabs_dashboard_url

    assert_response :success
    assert_select "h1", /Central de Comandas/
    assert_select "td", /João Silva/
  end

  test "dashboard filters by status" do
    sign_in users(:admin)
    Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "Comanda Aberta")
    Tab.create!(room: rooms(:two), opened_by: users(:admin), guest_identifier: "Comanda Paga", status: :paid)

    get tabs_dashboard_url, params: { status: "open" }

    assert_response :success
    assert_select "td", /Comanda Aberta/
    assert_select "td", text: /Comanda Paga/, count: 0
  end

  test "dashboard paginates when there are more than 20 tabs" do
    sign_in users(:admin)
    25.times do |i|
      Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "Hóspede #{i}")
    end

    get tabs_dashboard_url

    assert_response :success
    assert_select "nav[aria-label=?]", "Paginação"
    assert_select "ul.pagination"
    assert_select "a.page-link", minimum: 1
  end

  test "dashboard lists eligible rooms for new tab" do
    sign_in users(:admin)

    get tabs_dashboard_url

    assert_response :success
    assert_select "a[href=?]", new_room_tab_path(rooms(:one))
    # quarto em manutenção não é apto para nova comanda
    assert_select "a[href=?]", new_room_tab_path(rooms(:four)), count: 0
  end

  test "new tab form renders walk-in variant" do
    sign_in users(:admin)

    get new_room_tab_path(rooms(:one), walk_in: true)

    assert_response :success
    assert_select "h1", /Comanda Passante/
  end

  test "new tab form renders stay variant by default" do
    sign_in users(:admin)

    get new_room_tab_path(rooms(:one))

    assert_response :success
    assert_select "h1", text: /Nova Comanda/
    assert_select "h1", text: /Passante/, count: 0
    assert_select "p", text: /Quarto #{rooms(:one).number}/
  end

  test "show renders item actions and add item modal" do
    sign_in users(:admin)
    tab = Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "João Silva")
    product = Product.create!(code: "TEST1", name: "Cerveja", category: :beer, price: 10.0)
    tab.tab_items.create!(product: product, added_by: users(:admin), quantity: 2, unit_price: 10.0)

    get room_tab_path(rooms(:one), tab)

    assert_response :success
    assert_select "form[action=?]", room_tab_tab_items_path(rooms(:one), tab)
    assert_select "form[action=?]", update_quantity_room_tab_tab_item_path(rooms(:one), tab, tab.tab_items.first)
  end

  test "index renders room tabs history" do
    sign_in users(:admin)
    Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "Fulano de Tal")

    get room_tabs_path(rooms(:one))

    assert_response :success
    assert_select "h1", /Comandas do Quarto #{rooms(:one).number}/
    assert_select "td", /Fulano de Tal/
  end

  test "transfer moves items and totals to destination tab" do
    sign_in users(:admin)
    source = Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "João Silva")
    product = Product.create!(code: "TEST2", name: "Cerveja", category: :beer, price: 10.0)
    source.tab_items.create!(product: product, added_by: users(:admin), quantity: 3, unit_price: 10.0)
    source.recalculate_totals!

    patch transfer_room_tab_path(rooms(:one), source), params: { target_room_id: rooms(:two).id }

    destination = Tab.order(:id).last
    assert_redirected_to room_tab_path(rooms(:two), destination)
    assert_equal 1, destination.active_items.count
    assert_equal 3, destination.active_items.sum(:quantity)
    assert_equal 30.0, destination.total.to_f
    assert_equal 0.0, source.reload.total.to_f

    # O dashboard deve refletir os valores na comanda de destino (formato pt-BR)
    get tabs_dashboard_url
    assert_response :success
    assert_match(/R\$ 30,00/, response.body)
    assert_select "td", text: /João Silva/
  end

  test "report requires authentication" do
    get tabs_report_url
    assert_redirected_to new_user_session_url
  end

  test "report renders revenue summary for paid tabs" do
    sign_in users(:admin)
    tab = Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "Cliente")
    product = Product.create!(code: "REP1", name: "Cerveja", category: :beer, price: 10.0)
    tab.tab_items.create!(product: product, added_by: users(:admin), quantity: 2, unit_price: 10.0)
    tab.recalculate_totals!
    tab.pay!(user: users(:admin))

    get tabs_report_url

    assert_response :success
    assert_select "h1", /Relatórios de Faturamento/
    assert_match(/R\$ 20,00/, response.body)
    assert_select "td", /Cerveja/
  end
end
