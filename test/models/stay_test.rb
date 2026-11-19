require "test_helper"

class StayTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 1, 5, 15, 0, 0)
  end

  teardown do
    Current.reset
    travel_back
  end

  test "define valor e data a partir do período no check-in" do
    stay = build_stay(price_period_id: 1, check_in: Time.zone.local(2026, 1, 5, 15, 0, 0))

    assert stay.save
    assert_equal 18.0, stay.total_value.to_f
    assert_equal Date.new(2026, 1, 5), stay.date
    assert_equal Date.new(2026, 1, 5).cweek, stay.week_number
  end

  test "rejeita período horário durante a madrugada" do
    stay = build_stay(price_period_id: 1, check_in: Time.zone.local(2026, 1, 5, 23, 0, 0))

    assert_not stay.valid?
    assert stay.errors[:price_period_id].any?
  end

  test "rejeita período de pernoite durante o dia" do
    stay = build_stay(price_period_id: 3, check_in: Time.zone.local(2026, 1, 5, 15, 0, 0))

    assert_not stay.valid?
    assert stay.errors[:price_period_id].any?
  end

  test "aceita período de pernoite à noite" do
    stay = build_stay(price_period_id: 3, check_in: Time.zone.local(2026, 1, 5, 23, 0, 0))

    assert stay.valid?
  end

  test "sanitiza a observação antes de salvar" do
    stay = build_stay(
      price_period_id: 1,
      check_in: Time.zone.local(2026, 1, 5, 15, 0, 0),
      observation: "<b>Cliente</b> <script>alert(1)</script>preferiu quarto silencioso"
    )

    stay.save!

    assert_no_match(/<[^>]+>/, stay.observation)
    assert_includes stay.observation, "Cliente"
  end

  test "registra auditoria ao alterar o valor total" do
    stay = stays(:one)
    Current.user = users(:admin)

    assert_difference -> { StayAuditLog.count }, 1 do
      stay.update!(total_value: stay.total_value + 5)
    end

    log = StayAuditLog.last
    assert_equal "total_value", log.field_name
    assert log.value_change?
    assert_equal users(:admin), log.user
  end

  private

  def build_stay(attributes)
    Stay.new(
      { room: rooms(:one), user: users(:admin) }.merge(attributes)
    )
  end
end
