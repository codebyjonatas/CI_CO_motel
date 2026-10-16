module StaysHelper
  def stay_status_badge_class(status)
    case status
    when "active"      then "badge-primary"
    when "completed"   then "badge-success"
    when "cancelled"   then "bg-danger"
    else "bg-secondary"
    end
  end

  def stay_status_icon(status)
    case status
    when "active"      then '<i class="bi bi-play-circle-fill me-1"></i>'.html_safe
    when "completed"   then '<i class="bi bi-check-circle-fill me-1"></i>'.html_safe
    when "cancelled"   then '<i class="bi bi-x-circle-fill me-1"></i>'.html_safe
    else '<i class="bi bi-question-circle me-1"></i>'.html_safe
    end
  end

  def stay_status_label(status)
    case status
    when "active"      then "Em andamento"
    when "completed"   then "Finalizada"
    when "cancelled"   then "Cancelada"
    else status.humanize
    end
  end
end
