module Tabs
  class TransferService < ApplicationService
    def initialize(source_tab:, target_room:, target_stay: nil, user:, notes: nil)
      @source_tab = source_tab
      @target_room = target_room
      @target_stay = target_stay
      @user = user
      @notes = notes
    end

    def call
      return failure("Comanda de origem não está aberta") unless @source_tab.open?
      return failure("Quarto de destino não disponível") unless @target_room.available? || @target_room.occupied?
      return failure("Comanda de origem não possui itens") if @source_tab.active_items.empty?

      @target_stay ||= @target_room.current_stay

      Tab.transaction do
        new_tab = @source_tab.transfer_to!(
          target_room: @target_room,
          target_stay: @target_stay,
          user: @user,
          notes: @notes
        )

        RoomStatusLog.create!(
          room: @source_tab.room,
          stay: @source_tab.stay,
          user: @user,
          from_status: @source_tab.room.status,
          to_status: @source_tab.room.status,
          trigger: :manual,
          notes: "Comanda ##{@source_tab.id} transferida para quarto ##{@target_room.number} (comanda ##{new_tab.id})"
        )

        RoomStatusLog.create!(
          room: @target_room,
          stay: @target_stay,
          user: @user,
          from_status: @target_room.status,
          to_status: @target_room.status,
          trigger: :manual,
          notes: "Comanda ##{new_tab.id} recebida do quarto ##{@source_tab.room.number} (comanda ##{@source_tab.id})"
        )

        success(new_tab)
      end
    rescue StandardError => e
      failure(e.message)
    end
  end
end
