require "test_helper"

class RoomStatusLogTest < ActiveSupport::TestCase
  test "casts string statuses to integer enum values" do
    log = RoomStatusLog.create!(
      room: rooms(:one),
      user: users(:admin),
      from_status: "occupied",
      to_status: "dirty",
      trigger: :check_out
    )

    assert_equal "occupied", log.from_status
    assert_equal "dirty", log.to_status
    assert log.from_status_occupied?
    assert log.to_status_dirty?

    # Garante que o banco recebeu os valores do enum (1 e 2), não 0
    assert_equal 1, raw_status(log, :from_status)
    assert_equal 2, raw_status(log, :to_status)
  end

  test "room status change records correct from and to values" do
    room = rooms(:one)
    room.update!(status: :cleaning)

    log = RoomStatusLog.where(room: room).order(:id).last

    assert_equal "available", log.from_status
    assert_equal "cleaning", log.to_status
    assert_equal Room.statuses[:available], raw_status(log, :from_status)
    assert_equal Room.statuses[:cleaning], raw_status(log, :to_status)
  end

  private

  def raw_status(log, column)
    RoomStatusLog.connection.select_value(
      "SELECT #{column} FROM room_status_logs WHERE id = #{log.id}"
    ).to_i
  end
end
