class Stay < ApplicationRecord
  belongs_to :room
  belongs_to :user
  # price_period_id mantido para histórico, mas associação AR removida
  # Usa PricePeriodConfig para configuração estática dos períodos

  has_many :tabs, dependent: :restrict_with_error
  has_many :stay_guests, dependent: :destroy
  has_many :room_status_logs, dependent: :nullify
  has_many :stay_audit_logs, dependent: :destroy
  has_one :main_guest, -> { where(main_guest: true) }, class_name: "StayGuest"

  accepts_nested_attributes_for :stay_guests, allow_destroy: true, reject_if: :all_blank

  enum :status, { active: 0, completed: 1, cancelled: 2 }

  validates :check_in, presence: true
  validates :date, presence: true
  validates :week_number, presence: true
  validates :total_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_period_id, presence: true, on: :create
  validate :price_period_compatible_with_checkin_time, on: :create

  before_validation :set_date_and_week, on: :create
  before_validation :set_total_value_from_period, on: :create
  before_validation :sanitize_observation
  after_update :audit_changes, if: :saved_change_to_total_value_or_observation?

  scope :today, -> { where(date: Date.current) }
  scope :active_stays, -> { where(status: :active) }
  scope :ordered, -> { order(check_in: :desc) }

  # Retorna config do período (hash com name, price, duration_minutes, overnight)
  # Prioriza price_period_id (legado), fallback para código se necessário
  def price_period
    @price_period ||= if price_period_id.present?
                        PricePeriodConfig.find_by_id(price_period_id)
    else
                        PricePeriodConfig.find(read_attribute(:price_period_code))
    end
  end

  # Para compatibilidade com views que usam price_period.name, price_period.price, etc.
  def price_period_name
    price_period&.dig(:name)
  end

  def price_period_price
    price_period&.dig(:price) || 0
  end

  def price_period_duration_minutes
    price_period&.dig(:duration_minutes) || 0
  end

  def price_period_overnight?
    price_period&.dig(:overnight) == true
  end

  def active_tab
    tabs.where(status: [ :open, :closed ]).order(:created_at).last
  end

  def tab_balance
    tabs.where(status: [ :open, :closed ]).sum(:total)
  end

  def total_account_balance
    (total_value || 0) + tab_balance
  end

  def update_account_balance!
    touch(:updated_at)
  end

  def can_check_out?
    true
  end

  private

  def set_date_and_week
    self.date = check_in.to_date if check_in.present?
    self.week_number = date&.cweek
  end

  def set_total_value_from_period
    return if price_period.blank?
    self.total_value = price_period[:price]
  end

  def price_period_compatible_with_checkin_time
    return if price_period.blank? || check_in.blank?

    period = price_period
    checkin_hour = check_in.hour

    # Períodos pernoite (overnight): permitidos das 22h às 6h
    # Períodos horários (não overnight): permitidos das 6h às 22h
    if period[:overnight]
      unless checkin_hour >= 22 || checkin_hour < 6
        errors.add(:price_period_id, "Període pernote só pode ser selecionado entre 22h e 6h")
      end
    else
      if checkin_hour >= 22 || checkin_hour < 6
        errors.add(:price_period_id, "Període horário não pode ser selecionado entre 22h e 6h")
      end
    end
  end

  def sanitize_observation
    return if observation.blank?
    self.observation = Rails::Html::FullSanitizer.new.sanitize(observation)
  end

  def saved_change_to_total_value_or_observation?
    saved_change_to_total_value? || saved_change_to_observation?
  end

  def audit_changes
    auditor = Current.user || User.system_user

    if saved_change_to_total_value?
      StayAuditLog.create!(
        stay: self,
        user: auditor,
        field_name: "total_value",
        audit_action: :value_change,
        previous_value: total_value_before_last_save&.to_s,
        new_value: total_value&.to_s,
        notes: "Alteração manual de valor total (ex: extras, consumos)"
      )
    end

    if saved_change_to_observation?
      StayAuditLog.create!(
        stay: self,
        user: auditor,
        field_name: "observation",
        audit_action: :observation_change,
        previous_value: observation_before_last_save,
        new_value: observation,
        notes: "Atualização de observação"
      )
    end
  end
end
