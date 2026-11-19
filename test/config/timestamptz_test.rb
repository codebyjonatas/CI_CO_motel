require "test_helper"

class TimestamptzTest < ActiveSupport::TestCase
  test "colunas de data/hora usam timestamptz no PostgreSQL" do
    columns = ActiveRecord::Base.connection.columns(:stays).index_by(&:name)

    %w[check_in check_out created_at updated_at].each do |name|
      assert_includes columns.fetch(name).sql_type, "with time zone",
        "stays.#{name} deveria ser timestamp with time zone"
    end

    room_columns = ActiveRecord::Base.connection.columns(:rooms).index_by(&:name)
    assert_includes room_columns.fetch("quarantine_until").sql_type, "with time zone"
    assert_includes room_columns.fetch("cleaning_started_at").sql_type, "with time zone"
  end

  test "a aplicação exibe horários no fuso configurado e grava em UTC" do
    assert_equal "America/Sao_Paulo", Time.zone.name
    assert_equal :utc, ActiveRecord.default_timezone
  end

  test "o instante gravado é preservado na leitura em outro fuso" do
    travel_to Time.utc(2026, 1, 5, 18, 0, 0) do
      stay = stays(:one)
      stay.update!(check_in: Time.current)

      assert_equal Time.utc(2026, 1, 5, 18, 0, 0), stay.reload.check_in

      Time.use_zone("America/Sao_Paulo") do
        assert_equal "2026-01-05 15:00:00", stay.check_in.strftime("%Y-%m-%d %H:%M:%S")
      end
    end
  end
end
