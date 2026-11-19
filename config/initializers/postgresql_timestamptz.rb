# Armazena colunas :datetime como "timestamp with time zone" (timestamptz).
#
# Vantagens:
# - o PostgreSQL guarda o instante absoluto (UTC) e converte na leitura;
# - não há ambiguidade em horário de verão ou mudança de fuso do servidor;
# - o Rails continua expondo o valor como Time no fuso de config.time_zone.
#
# Migrações antigas que usam :timestamp seguem criando "timestamp without
# time zone"; use :timestamptz explicitamente quando precisar do tipo sem fuso.
ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
