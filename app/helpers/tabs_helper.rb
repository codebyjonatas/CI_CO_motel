module TabsHelper
  def badge_for_tab_status(status)
    case status.to_s
    when "open"
      content_tag :span, "Aberta", class: "badge bg-success"
    when "closed"
      content_tag :span, "Fechada", class: "badge bg-warning text-dark"
    when "paid"
      content_tag :span, "Paga", class: "badge bg-dark"
    when "cancelled"
      content_tag :span, "Cancelada", class: "badge bg-danger"
    when "transferred"
      content_tag :span, "Transferida", class: "badge bg-info"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end

  def badge_for_item_status(status)
    case status.to_s
    when "active"
      content_tag :span, "Ativo", class: "badge bg-success"
    when "voided"
      content_tag :span, "Estornado", class: "badge bg-danger"
    when "transferred"
      content_tag :span, "Transferido", class: "badge bg-info"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end
end
