module TabsHelper
  def badge_for_tab_status(status)
    label, modifier, icon =
      case status.to_s
      when "open"        then [ "Aberta", "badge-success", "bi-unlock-fill" ]
      when "closed"      then [ "Fechada", "badge-warning", "bi-lock-fill" ]
      when "paid"        then [ "Paga", "badge-dark", "bi-check2-circle" ]
      when "cancelled"   then [ "Cancelada", "badge-danger", "bi-x-circle-fill" ]
      when "transferred" then [ "Transferida", "badge-info", "bi-arrow-left-right" ]
      else [ status.to_s.humanize, "badge-muted", "bi-dot" ]
      end

    badge_tag(label, modifier, icon)
  end

  def badge_for_item_status(status)
    label, modifier, icon =
      case status.to_s
      when "active"      then [ "Ativo", "badge-success", "bi-check2-circle" ]
      when "voided"      then [ "Estornado", "badge-danger", "bi-slash-circle" ]
      when "transferred" then [ "Transferido", "badge-info", "bi-arrow-left-right" ]
      else [ status.to_s.humanize, "badge-muted", "bi-dot" ]
      end

    badge_tag(label, modifier, icon)
  end

  def tab_type_badge(tab)
    if tab.walk_in?
      badge_tag("Passante", "badge-warning", "bi-person-walking")
    else
      badge_tag("Estadia", "badge-primary", "bi-journal-text")
    end
  end

  private

  def badge_tag(label, modifier, icon)
    content = safe_join([ tag.i(class: "bi #{icon} me-1", aria: { hidden: "true" }), label ])
    content_tag :span, content, class: "badge-custom #{modifier}"
  end
end
