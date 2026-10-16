module Tabs
  class CreateService < ApplicationService
    def initialize(room:, opened_by:, guest_identifier: nil, stay: nil, notes: nil)
      @room = room
      @opened_by = opened_by
      @guest_identifier = guest_identifier
      @stay = stay
      @notes = notes
    end

    def call
      return failure("Quarto não está disponível para nova comanda") unless @room.available? || @room.occupied?
      return failure("Quarto já possui comanda aberta") if @room.has_open_tab?

      guest_id = @guest_identifier || (@stay&.main_guest&.full_name || "Hóspede Quarto #{@room.number}")

      Tab.transaction do
        tab = Tab.create!(
          room: @room,
          stay: @stay,
          opened_by: @opened_by,
          guest_identifier: guest_id,
          notes: @notes,
          status: :open
        )

        log_room_status_change(tab, :check_in)

        success(tab)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def log_room_status_change(tab, trigger)
      RoomStatusLog.create!(
        room: @room,
        stay: @stay,
        user: @opened_by,
        from_status: @room.status_before_last_save || @room.status,
        to_status: @room.status,
        trigger: trigger,
        notes: "Comanda ##{tab.id} aberta para #{tab.guest_identifier}"
      )
    end
  end
end
