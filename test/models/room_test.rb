require "test_helper"

class RoomTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 1, 5, 15, 0, 0)
    @room = rooms(:two)
  end

  teardown { travel_back }

  test "check-in ocupa o quarto e check-out o envia para limpeza" do
    @room.update!(status: :available, quarantine_until: nil)

    @room.check_in!
    assert @room.status_occupied?

    @room.check_out!
    assert @room.status_dirty?
    assert_equal "check_out", @room.room_status_logs.last.trigger
  end

  test "não permite check-in durante a quarentena" do
    @room.update!(status: :available, quarantine_until: 5.minutes.from_now)

    assert_not @room.can_checkin?
    assert_raises(AASM::InvalidTransition) { @room.check_in! }
  end

  test "ciclo de limpeza só libera o quarto após a quarentena" do
    @room.update!(status: :dirty)

    @room.start_cleaning!
    assert @room.status_cleaning?

    @room.finish_cleaning!
    assert @room.status_quarantine?
    assert @room.quarantine_until > Time.current

    assert_raises(AASM::InvalidTransition) { @room.release_from_quarantine! }

    travel 31.minutes do
      @room.release_from_quarantine!
    end

    assert @room.status_available?
  end
end
