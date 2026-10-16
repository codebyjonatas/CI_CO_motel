class Room < ApplicationRecord
  include RoomAuditable
  include RoomAvailability
  include AASM

  has_many :stays, dependent: :restrict_with_error
  has_many :tabs, dependent: :restrict_with_error
  has_many :cleaning_logs, dependent: :destroy
  belongs_to :cleaned_by, class_name: "User", optional: true

  # Estados: 0=available, 1=occupied, 2=dirty, 3=cleaning, 4=quarantine, 5=maintenance
  enum :status, {
    available: 0,       # Livre para nova estadia
    occupied: 1,        # Ocupado (check-in ativo)
    dirty: 2,           # Desocupado, aguardando limpeza
    cleaning: 3,        # Em limpeza
    quarantine: 4,      # Limpo, em quarentena (30min)
    maintenance: 5      # Manutenção
  }, prefix: true

  validates :number, presence: true, uniqueness: true
  validates :daily_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }

  aasm column: :status, enum: true do
    state :available, initial: true
    state :occupied
    state :dirty
    state :cleaning
    state :quarantine
    state :maintenance

    event :check_in do
      transitions from: :available, to: :occupied, guard: :can_checkin?
    end

    event :check_out do
      transitions from: :occupied, to: :dirty
    end

    event :start_cleaning do
      transitions from: :dirty, to: :cleaning
    end

    event :finish_cleaning do
      transitions from: :cleaning, to: :quarantine, after: :set_quarantine
    end

    event :release_from_quarantine do
      transitions from: :quarantine, to: :available, guard: :quarantine_expired?
    end

    event :to_maintenance do
      transitions from: [ :available, :dirty ], to: :maintenance
    end

    event :back_from_maintenance do
      transitions from: :maintenance, to: :available
    end
  end

  def can_checkin?
    status_available? && quarantine_expired?
  end

  def quarantine_expired?
    quarantine_until.nil? || quarantine_until <= Time.current
  end

  def time_until_available
    return 0 if status_available? && quarantine_expired?
    return nil unless quarantine_until
    [ (quarantine_until - Time.current).to_i, 0 ].max
  end

  def status_badge_class
    case status
    when "available" then "bg-success"
    when "occupied" then "bg-warning text-dark"
    when "dirty" then "bg-danger"
    when "cleaning" then "bg-info"
    when "quarantine" then "bg-secondary"
    when "maintenance" then "bg-dark"
    else "bg-secondary"
    end
  end

  def status_label
    case status
    when "available" then "Disponível"
    when "occupied" then "Ocupado"
    when "dirty" then "Sujo (aguardando limpeza)"
    when "cleaning" then "Em limpeza"
    when "quarantine" then "Quarentena (#{time_until_available / 60}min)"
    when "maintenance" then "Manutenção"
    end
  end

  private

  def set_quarantine
    self.quarantine_until = RoomCleaningConfig.quarantine_duration.from_now
    self.cleaning_finished_at = Time.current
    self.cleaned_by = Current.user
    save!
  end
end
