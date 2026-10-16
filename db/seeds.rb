puts "=== Criando usuários ==="
admin = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.name = "Administrador"
  u.password = "123456"
end
admin.add_role :admin

attendant = User.find_or_create_by!(email: "atendente@admin.com") do |u|
  u.name = "Atendente"
  u.password = "123456"
end
attendant.add_role :attendant

puts "=== Criando quartos ==="
[ 7, 8, 9, 10 ].each do |n|
  Room.find_or_create_by!(number: n.to_s) do |r|
    r.floor = 1
  end
end

puts "=== Criando períodos ==="
periods = [
  { code: "one_hour",         name: "1 Hora",           price: 18, duration_minutes: 60,  overnight: false },
  { code: "two_hours",        name: "2 Horas",          price: 32, duration_minutes: 120, overnight: false },
  { code: "basic_overnight",  name: "Pernoite Básico",  price: 60, duration_minutes: 720, overnight: true  },
  { code: "advanced_overnight", name: "Pernoite Avançado", price: 70, duration_minutes: 720, overnight: true  }
]

periods.each do |attrs|
  PricePeriod.find_or_create_by!(code: attrs[:code]) do |p|
    p.name = attrs[:name]
    p.price = attrs[:price]
    p.duration_minutes = attrs[:duration_minutes]
    p.overnight = attrs[:overnight]
  end
end

puts "=== Criando produtos do bar ==="
products = [
  # Cervejas
  { code: "BEER_600",     name: "Cerveja 600ml",       category: :beer,       price: 12.00, tax_rate: 10 },
  { code: "BEER_350",     name: "Cerveja 350ml",       category: :beer,       price: 8.00,  tax_rate: 10 },
  { code: "BEER_DRAFT",   name: "Chope 300ml",         category: :beer,       price: 9.00,  tax_rate: 10 },
  { code: "BEER_DRAFT_500", name: "Chope 500ml",       category: :beer,       price: 14.00, tax_rate: 10 },

  # Destilados
  { code: "WHISKEY_SHOT", name: "Dose Whisky",         category: :spirits,    price: 18.00, tax_rate: 15 },
  { code: "VODKA_SHOT",   name: "Dose Vodka",          category: :spirits,    price: 15.00, tax_rate: 15 },
  { code: "GIN_SHOT",     name: "Dose Gin",            category: :spirits,    price: 16.00, tax_rate: 15 },
  { code: "CACHACA_SHOT", name: "Dose Cachaça",        category: :spirits,    price: 10.00, tax_rate: 15 },
  { code: "TEQUILA_SHOT", name: "Dose Tequila",        category: :spirits,    price: 20.00, tax_rate: 15 },

  # Refrigerantes
  { code: "SODA_CAN",     name: "Refrigerante Lata",   category: :soft_drink, price: 6.00,  tax_rate: 10 },
  { code: "SODA_600",     name: "Refrigerante 600ml",  category: :soft_drink, price: 8.00,  tax_rate: 10 },
  { code: "WATER_500",    name: "Água 500ml",          category: :water,      price: 4.00,  tax_rate: 0  },
  { code: "WATER_SPARK",  name: "Água com Gás 500ml",  category: :water,      price: 5.00,  tax_rate: 0  },
  { code: "JUICE",        name: "Suco Natural",        category: :soft_drink, price: 9.00,  tax_rate: 10 },

  # Petiscos
  { code: "SNACK_PEANUT", name: "Amendoim",            category: :snack,      price: 8.00,  tax_rate: 10 },
  { code: "SNACK_CHIPS",  name: "Batata Frita",        category: :snack,      price: 12.00, tax_rate: 10 },
  { code: "SNACK_BOARD",  name: "Porção Mista",        category: :snack,      price: 28.00, tax_rate: 10 },
  { code: "SNACK_CHEESE", name: "Tábua de Queijos",    category: :snack,      price: 35.00, tax_rate: 10 }
]

products.each do |attrs|
  Product.find_or_create_by!(code: attrs[:code]) do |p|
    p.name = attrs[:name]
    p.category = attrs[:category]
    p.price = attrs[:price]
    p.tax_rate = attrs[:tax_rate]
    p.active = true
  end
end

puts "=== Criando regras de preço dinâmico (Happy Hour) ==="
# Happy Hour: 17h-20h, segunda a sexta
happy_hour = ProductPriceRule.find_or_create_by!(product: Product.find_by(code: "BEER_600"), name: "Happy Hour") do |r|
  r.price = 8.00
  r.priority = 10
  r.days_of_week = [ 1, 2, 3, 4, 5 ] # seg-sex
  r.starts_at = "17:00"
  r.ends_at = "20:00"
  r.active = true
end

# Happy Hour chope
ProductPriceRule.find_or_create_by!(product: Product.find_by(code: "BEER_DRAFT"), name: "Happy Hour") do |r|
  r.price = 6.00
  r.priority = 10
  r.days_of_week = [ 1, 2, 3, 4, 5 ]
  r.starts_at = "17:00"
  r.ends_at = "20:00"
  r.active = true
end

# Promoção fim de semana: doses com desconto
ProductPriceRule.find_or_create_by!(product: Product.find_by(code: "WHISKEY_SHOT"), name: "Fim de Semana") do |r|
  r.price = 15.00
  r.priority = 5
  r.days_of_week = [ 0, 6 ] # dom, sab
  r.active = true
end

ProductPriceRule.find_or_create_by!(product: Product.find_by(code: "VODKA_SHOT"), name: "Fim de Semana") do |r|
  r.price = 12.00
  r.priority = 5
  r.days_of_week = [ 0, 6 ]
  r.active = true
end

# Promoção madrugada: petiscos
ProductPriceRule.find_or_create_by!(product: Product.find_by(code: "SNACK_BOARD"), name: "Madrugada") do |r|
  r.price = 22.00
  r.priority = 5
  r.starts_at = "00:00"
  r.ends_at = "06:00"
  r.active = true
end

puts "Seed concluído! #{User.count} usuários, #{Room.count} quartos, #{PricePeriod.count} períodos, #{Product.count} produtos, #{ProductPriceRule.count} regras de preço."
