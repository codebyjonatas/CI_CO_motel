require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "index requires authentication" do
    get rooms_url
    assert_redirected_to new_user_session_url
  end

  test "index renders operational summary" do
    sign_in users(:admin)

    get rooms_url

    assert_response :success
    assert_select "h1", /Quartos/
    assert_select ".card", minimum: 1
  end

  test "history renders the room timeline" do
    sign_in users(:admin)

    get history_room_url(rooms(:one))

    assert_response :success
    assert_select "h1", /Histórico do Quarto #{rooms(:one).number}/
  end

  test "start_cleaning transitions a dirty room to cleaning" do
    sign_in users(:admin)
    room = rooms(:one)
    room.update!(status: :dirty)

    patch start_cleaning_room_url(room)

    assert_redirected_to room_url(room)
    assert_equal "cleaning", room.reload.status
  end

  test "start_cleaning is rejected when the room is not dirty" do
    sign_in users(:admin)
    room = rooms(:one)

    patch start_cleaning_room_url(room)

    assert_redirected_to room_url(room)
    assert_equal "available", room.reload.status
    assert_match(/não está aguardando limpeza/, flash[:alert])
  end

  test "finish_cleaning moves the room to quarantine and finishes the log" do
    sign_in users(:admin)
    room = rooms(:one)
    room.update!(status: :dirty)
    room.start_cleaning!
    log = room.cleaning_logs.create!(cleaned_by: users(:admin), started_at: Time.current, status: :started)

    patch finish_cleaning_room_url(room)

    assert_redirected_to room_url(room)
    assert_equal "quarantine", room.reload.status
    assert_equal "finished", log.reload.status
    assert_not_nil log.finished_at
  end

  test "release_quarantine is blocked until the quarantine expires" do
    sign_in users(:admin)
    room = quarantine_room

    patch release_quarantine_room_url(room)

    assert_redirected_to room_url(room)
    assert_equal "quarantine", room.reload.status
    assert_match(/não expirou/, flash[:alert])
  end

  test "release_quarantine frees the room once the quarantine expires" do
    sign_in users(:admin)
    room = quarantine_room
    room.update_column(:quarantine_until, 1.minute.ago)

    patch release_quarantine_room_url(room)

    assert_redirected_to room_url(room)
    assert_equal "available", room.reload.status
    assert_equal "approved", room.cleaning_logs.last.status
  end

  test "attendant can operate the cleaning cycle" do
    sign_in users(:attendant)
    room = rooms(:one)
    room.update!(status: :dirty)

    patch start_cleaning_room_url(room)

    assert_equal "cleaning", room.reload.status
  end

  private

  def quarantine_room
    room = rooms(:one)
    room.update!(status: :dirty)
    room.start_cleaning!
    log = room.cleaning_logs.create!(cleaned_by: users(:admin), started_at: Time.current, status: :started)
    log.finish!(user: users(:admin))
    room
  end
end
