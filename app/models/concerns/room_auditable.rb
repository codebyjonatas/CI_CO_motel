module RoomAuditable
  extend ActiveSupport::Concern

  included do
    has_many :room_status_logs, dependent: :destroy
    has_many :tabs, dependent: :restrict_with_error
    has_many :active_tabs, -> { where(status: [ :open, :closed ]) }, class_name: "Tab"

    after_update :log_status_change, if: :saved_change_to_status?
  end

  def current_tab
    active_tabs.order(:created_at).last
  end

  def has_open_tab?
    active_tabs.where(status: :open).exists?
  end

  def tab_balance
    active_tabs.where(status: [ :open, :closed ]).sum(:total)
  end

  def current_stay
    stays.active_stays.first
  end

  private

  def log_status_change
    return if status_before_last_save.nil?

    RoomStatusLog.create!(
      room: self,
      stay: current_stay,
      user: Current.user || User.system_user,
      from_status: status_before_last_save,
      to_status: status,
      trigger: infer_trigger,
      notes: "Mudança automática de status"
    )
  end

  def infer_trigger
    from = status_before_last_save
    to = status

    case [ from, to ]
    when [ "available", "occupied" ] then :check_in
    when [ "occupied", "available" ] then :check_out
    when [ "occupied", "cancelled" ] then :cancel
    else
      if to == "maintenance"
        :maintenance_start
      elsif from == "maintenance"
        :maintenance_end
      else
        :manual
      end
    end
  end
end
