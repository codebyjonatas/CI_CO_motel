module RoomAvailability
  extend ActiveSupport::Concern

  class_methods do
    # Quartos disponíveis para check-in AGORA (considera quarentena)
    def available_for_checkin
      where(status: :available).where("quarantine_until IS NULL OR quarantine_until <= ?", Time.current)
    end

    # Quartos que estarão disponíveis em X minutos
    def becoming_available_within(minutes)
      where(status: :quarantine)
        .where("quarantine_until <= ?", minutes.minutes.from_now)
    end

    # Quartos no ciclo de limpeza
    def in_cleaning_cycle
      where(status: [ :dirty, :cleaning, :quarantine ])
    end

    # Quartos ocupados ou sujos (precisam de atenção)
    def occupied_or_dirty
      where(status: [ :occupied, :dirty ])
    end

    # Dashboard de status operacional
    def operational_status
      group(:status).count
    end

    # Resumo para dashboard
    def dashboard_summary
      {
        available: available_for_checkin.count,
        occupied: where(status: :occupied).count,
        dirty: where(status: :dirty).count,
        cleaning: where(status: :cleaning).count,
        quarantine: where(status: :quarantine).count,
        maintenance: where(status: :maintenance).count,
        becoming_available_30min: becoming_available_within(30).count
      }
    end
  end

  def current_stay
    stays.active_stays.first
  end

  def current_tab
    tabs.where(status: [ :open, :closed ]).order(:created_at).last
  end

  def has_open_tab?
    tabs.where(status: :open).exists?
  end

  def tab_balance
    tabs.where(status: [ :open, :closed ]).sum(:total)
  end

  def active_cleaning_log
    cleaning_logs.where(status: [ :started, :finished ]).recent.first
  end

  def last_completed_cleaning
    cleaning_logs.where(status: [ :approved, :rejected ]).recent.first
  end
end
