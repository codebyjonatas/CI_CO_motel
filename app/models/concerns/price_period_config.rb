# Configuração centralizada dos períodos de preço fixos.
# Substitui o model PricePeriod (ActiveRecord) por uma estrutura estática.
module PricePeriodConfig
  # Código => configuração do período
  PERIODS = {
    "one_hour" => {
      code: "one_hour",
      name: "1 Hora",
      price: 18.00,
      duration_minutes: 60,
      overnight: false
    },
    "two_hours" => {
      code: "two_hours",
      name: "2 Horas",
      price: 32.00,
      duration_minutes: 120,
      overnight: false
    },
    "basic_overnight" => {
      code: "basic_overnight",
      name: "Pernoite Básico",
      price: 60.00,
      duration_minutes: 720,
      overnight: true
    },
    "advanced_overnight" => {
      code: "advanced_overnight",
      name: "Pernoite Avançado",
      price: 70.00,
      duration_minutes: 720,
      overnight: true
    }
  }.freeze

  # Retorna array ordenado para selects/formulários: [[name, id], ...]
  def self.select_options
    PERIODS.values.each_with_index.map { |p, i| [ p[:name], i + 1 ] }
  end

  # Busca config por código (string)
  def self.find(code)
    PERIODS[code.to_s]
  end

  # Busca config por ID (compatibilidade com price_period_id existente)
  # Mapeia ID legado (1-4) para código
  def self.find_by_id(id)
    legacy_map = {
      1 => "one_hour",
      2 => "two_hours",
      3 => "basic_overnight",
      4 => "advanced_overnight"
    }
    code = legacy_map[id.to_i]
    code ? PERIODS[code] : nil
  end

  # Todos os períodos como array de hashes
  def self.all
    PERIODS.values
  end

  # Verifica se um código existe
  def self.exists?(code)
    PERIODS.key?(code.to_s)
  end
end
