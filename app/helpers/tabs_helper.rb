module TabsHelper
  def badge_for_tab_status(status)
    label, modifier =
      case status.to_s
      when "open"        then [ "Aberta", "badge-success" ]
      when "closed"      then [ "Fechada", "badge-warning" ]
      when "paid"        then [ "Paga", "badge-dark" ]
      when "cancelled"   then [ "Cancelada", "badge-danger" ]
      when "transferred" then [ "Transferida", "badge-info" ]
      else [ status.to_s.humanize, "badge-muted" ]
      end

    content_tag :span, label, class: "badge-custom #{modifier}"
  end

  def badge_for_item_status(status)
    label, modifier =
      case status.to_s
      when "active"      then [ "Ativo", "badge-success" ]
      when "voided"      then [ "Estornado", "badge-danger" ]
      when "transferred" then [ "Transferido", "badge-info" ]
      else [ status.to_s.humanize, "badge-muted" ]
      end

    content_tag :span, label, class: "badge-custom #{modifier}"
  end

  def tab_type_badge(tab)
    if tab.walk_in?
      content_tag :span, "Passante", class: "badge-custom badge-warning"
    else
      content_tag :span, "Estadia", class: "badge-custom badge-primary"
    end
  end
end
