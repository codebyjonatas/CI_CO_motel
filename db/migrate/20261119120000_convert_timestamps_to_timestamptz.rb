# Converte todas as colunas de data/hora do schema principal para timestamptz.
#
# As colunas antigas eram "timestamp without time zone" e o Rails gravava nelas
# o horário em UTC (default_timezone = :utc). Por isso a conversão usa
# `AT TIME ZONE 'UTC'`, que reinterpreta o valor existente como UTC e o
# converte para "timestamp with time zone" sem deslocar os instantes.
#
# Usamos ALTER TABLE nativo (em vez de change_column) para preservar a ordem
# física das colunas e a precisão de microssegundos usada pelo Rails.
class ConvertTimestampsToTimestamptz < ActiveRecord::Migration[8.1]
  def up
    alter_columns(from: "timestamp without time zone", to: "timestamptz(6)")
  end

  def down
    alter_columns(from: "timestamp with time zone", to: "timestamp(6)")
  end

  private

  def alter_columns(from:, to:)
    columns_with_type(from).each do |table, column|
      execute <<~SQL
        ALTER TABLE #{quote_table_name(table)}
        ALTER COLUMN #{quote_column_name(column)}
        TYPE #{to}
        USING #{quote_column_name(column)} AT TIME ZONE 'UTC'
      SQL
    end
  end

  # Lê o catálogo do PostgreSQL em vez de fixar a lista de tabelas/colunas,
  # assim nenhuma coluna datetime fica de fora (inclusive as do próprio Rails).
  def columns_with_type(data_type)
    select_rows(<<~SQL, "SCHEMA")
      SELECT table_name, column_name
      FROM information_schema.columns
      WHERE table_schema = ANY (current_schemas(false))
        AND data_type = #{quote(data_type)}
      ORDER BY table_name, ordinal_position
    SQL
  end
end
