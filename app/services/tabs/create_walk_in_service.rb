module Tabs
  class CreateWalkInService < ApplicationService
    def initialize(room:, guest_identifier:, opened_by:, notes: nil)
      @room = room
      @guest_identifier = guest_identifier
      @opened_by = opened_by
      @notes = notes
    end

    def call
      return failure("Quarto não está disponível") unless @room.available? || @room.occupied?
      return failure("Identificação do cliente é obrigatória") if @guest_identifier.blank?
      return failure("Quarto já possui comanda aberta") if @room.has_open_tab?

      Tab.transaction do
        tab = Tab.create!(
          room: @room,
          stay: nil,
          opened_by: @opened_by,
          guest_identifier: @guest_identifier,
          notes: @notes,
          status: :open
        )

        RoomStatusLog.create!(
          room: @room,
          stay: nil,
          user: @opened_by,
          from_status: @room.status,
          to_status: @room.status,
          trigger: :manual,
          notes: "Comanda passante aberta: #{@guest_identifier}"
        )

        success(tab)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
