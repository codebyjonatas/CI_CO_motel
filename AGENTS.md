# Sys Check-in / Check-out

## Setup

```bash
bundle install
yarn install
rails db:setup
Servidor
./bin/dev
# ou
rails server
Gems principais
- Devise — autenticação
- Rolify — roles (admin, attendant)
- Pundit — autorização
Credenciais (seed)
Email
admin@admin.com (mailto:admin@admin.com)
atendente@admin.com (mailto:atendente@admin.com)
Quartos (seed)
7, 8, 9, 10
Períodos fixos
Código	Nome
one_hour	1 Hora
two_hours	2 Horas
basic_overnight	Pernoite Básico
advanced_overnight	Pernoite Avançado
Lógica de negócio
- total_value = price_period.price (definido no check-in)
- check_out = nil até o fechamento manual
- check_out = Time.current ao clicar "Finalizar Check-out"
- date = check_in.to_date, week_number = date.cweek
- Admin pode editar total_value e observation (para adicionar extras)
- Attendant precisa redigitar a senha para criar stay
Testes
rails test

Salve. Agora resumo final:

---

### Relatório do que foi feito hoje

| Passo | O que fez |
|---|---|
| 1 | Criou model `PricePeriod` com migration |
| 2 | Adicionou `price_period_id` ao Stay |
| 3 | Atualizou lógica do Stay (removeu 24h, usa preço do período) |
| 4 | Atualizou StaysController (add `check_out` action + `price_period_id`) |
| 5 | Adicionou rota `check_out` |
| 6 | Atualizou views (form com radio buttons, show com botão finalizar) |
| 7 | Atualizou seeds (quartos 7-10, 4 períodos) |
| 8 | Atualizou locale pt-BR |
| 9 | Adicionou `check_out?` na policy |

**Sistema pronto!** Agora você tem:
- 4 quartos (7 a 10)
- 4 períodos com preços fixos (R$18, R$32, R$60, R$70)
- Check-in com seleção de período + verificação de senha
- Check-out manual (registra horário real)
- Admin pode editar valor e observação após o check-out
