module DiscountLimit
  class LimitExceeded < StandardError; end

  DEFAULTS = {
    attendant_max_percent: 15,
    attendant_max_absolute: 50.00,
    admin_max_percent: 100,
    admin_max_absolute: Float::INFINITY
  }.freeze

  module_function

  def config
    Rails.application.credentials.discount_limits || {}
  end

  def max_percent_for(role)
    case role
    when "admin" then config[:admin_max_percent] || DEFAULTS[:admin_max_percent]
    when "attendant" then config[:attendant_max_percent] || DEFAULTS[:attendant_max_percent]
    else 0
    end
  end

  def max_absolute_for(role)
    case role
    when "admin" then config[:admin_max_absolute] || DEFAULTS[:admin_max_absolute]
    when "attendant" then config[:attendant_max_absolute] || DEFAULTS[:attendant_max_absolute]
    else 0
    end
  end

  def validate!(user:, discount_percent:, discount_absolute:, tab_subtotal:)
    role = user.try(:role) || user.try(:roles)&.first&.name || "attendant"
    max_pct = max_percent_for(role)
    max_abs = max_absolute_for(role)

    if discount_percent > max_pct
      raise LimitExceeded, "Desconto de #{discount_percent}% excede o limite de #{max_pct}% para #{role}"
    end

    if discount_absolute > max_abs
      raise LimitExceeded, "Desconto de R$ #{discount_absolute} excede o limite de R$ #{max_abs} para #{role}"
    end

    if discount_absolute > tab_subtotal
      raise LimitExceeded, "Desconto não pode ser maior que o subtotal da comanda (R$ #{tab_subtotal})"
    end

    true
  end
end
