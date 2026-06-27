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

puts "Seed concluído! #{User.count} usuários, #{Room.count} quartos, #{PricePeriod.count} períodos."
