module RoomsHelper
  def room_status_badge_class(status)
    case status.to_s
    when "available"  then "badge-success"
    when "occupied"   then "badge-accent"
    when "dirty"      then "bg-danger text-white"
    when "cleaning"   then "bg-info text-dark"
    when "quarantine" then "bg-secondary text-white"
    when "maintenance" then "bg-warning text-dark"
    else "bg-secondary text-white"
    end
  end

  def room_status_icon(status)
    case status.to_s
    when "available"  then '<i class="bi bi-check-circle-fill me-1"></i>'
    when "occupied"   then '<i class="bi bi-person-fill me-1"></i>'
    when "dirty"      then '<i class="bi bi-exclamation-triangle-fill me-1"></i>'
    when "cleaning"   then '<i class="bi bi-stars me-1"></i>'
    when "quarantine" then '<i class="bi bi-hourglass-split me-1"></i>'
    when "maintenance" then '<i class="bi bi-tools me-1"></i>'
    else '<i class="bi bi-question-circle me-1"></i>'
    end.html_safe
  end

  def room_status_label(status)
    case status.to_s
    when "available"  then "Disponível"
    when "occupied"   then "Ocupado"
    when "dirty"      then "Sujo (limpeza pendente)"
    when "cleaning"   then "Em limpeza"
    when "quarantine" then "Quarentena"
    when "maintenance" then "Manutenção"
    else status.to_s.humanize
    end
  end

  def room_history_icon(category)
    case category.to_sym
    when :stay     then "bi-door-open-fill"
    when :tab      then "bi-receipt"
    when :cleaning then "bi-stars"
    when :status   then "bi-arrow-left-right"
    else "bi-circle"
    end
  end
end
