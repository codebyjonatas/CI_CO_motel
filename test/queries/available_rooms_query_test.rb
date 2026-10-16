require "test_helper"

class AvailableRoomsQueryTest < ActiveSupport::TestCase
  setup do
    @query = AvailableRoomsQuery.new
  end

  test "eligible_for_new_tab excludes rooms with an open tab" do
    Tab.create!(room: rooms(:one), opened_by: users(:admin), guest_identifier: "Comanda Aberta")

    eligible = @query.eligible_for_new_tab

    assert_not_includes eligible, rooms(:one)
    assert_includes eligible, rooms(:two)
  end

  test "eligible_for_new_tab excludes rooms not available or occupied" do
    eligible = @query.eligible_for_new_tab

    # quarto em manutenção (rooms(:four)) não é apto
    assert_not_includes eligible, rooms(:four)
  end

  test "available_for_checkin returns only available rooms" do
    available = @query.available_for_checkin

    assert_includes available, rooms(:one)
    assert_not_includes available, rooms(:four)
  end

  test "becoming_available_within returns rooms whose quarantine ends soon" do
    room = rooms(:two)
    room.update_columns(status: Room.statuses[:quarantine], quarantine_until: 10.minutes.from_now)

    result = @query.becoming_available_within(30)

    assert_includes result, room
    assert_not_includes result, rooms(:one)
  end
end
