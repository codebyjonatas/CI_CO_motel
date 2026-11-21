# MotelFlow — Sistema de Check-in/Check-out

App Rails 8.1 para gestão de quartos de hotel/motel com períodos de preço fixos.

## Início Rápido

```bash
bundle install && yarn install && rails db:setup
./bin/dev          # ou: rails server
```

## Comandos Principais

| Tarefa | Comando |
|--------|---------|
| Rodar testes | `rails test` |
| Rodar testes de sistema | `rails test:system` |
| Lint | `bin/rubocop` |
| Scan segurança (Ruby) | `bin/brakeman` |
| Scan segurança (JS) | `bin/importmap audit` |
| Build CSS | `yarn build:css` |
| Watch CSS | `yarn watch:css` |

## Arquitetura

- **Models**: `Stay`, `Room` (AASM: `available → occupied → dirty → cleaning → quarantine → maintenance`), `PricePeriod`, `User` (Devise + Rolify), `Tab`/`TabItem` (comandas do bar), `Product`/`ProductPriceRule`, `CleaningLog`, `RoomStatusLog`, `StayGuest`, `TabItemAudit`
- **Queries** (`app/queries`): `TabDashboardQuery`, `RoomHistoryQuery`, `AvailableRoomsQuery`, `TabReportQuery`
- **Services** (`app/services`): `Tabs::*`, `TabItems::*`, `Stays::CloseAccountService`, `Stays::CheckOutService`
- **Auth**: Devise, roles: `admin`, `attendant`
- **Authz**: Pundit policies (`StayPolicy`, `RoomPolicy`, `TabPolicy`, `TabItemPolicy`, `ProductPolicy`)
- **Frontend**: Bootstrap 5, Sass, importmap, Turbo/Stimulus

## Lógica de Negócio

- **PricePeriod** — períodos fixos com código/nome/preço/duração: `one_hour` (R$18/60min), `two_hours` (R$32/120min), `basic_overnight` (R$60/720min), `advanced_overnight` (R$70/720min)
- **Stay** — `total_value = price_period.price` (definido no check-in); `check_out` nil até finalização manual; `date`/`week_number` derivados do `check_in`
- **Check-in**: exige seleção de quarto, período, hora de entrada, **reentrada de senha do atendente**
- **Check-out**: botão manual → `Stays::CheckOutService` fecha as comandas abertas (`Stays::CloseAccountService`), define `check_out = Time.current`, `status = completed` e coloca o quarto em **`dirty`**, criando um `CleaningLog` (`started`)
- **Ciclo de limpeza**: `dirty --start_cleaning--> cleaning --finish_cleaning--> quarantine (30min) --release_from_quarantine--> available` (`CleaningLog`: `started → finished → approved/rejected`)
- **Comanda (Tab)**: aberta por quarto/estadia ou passante (`walk_in?`); `subtotal/total` recalculados a partir dos itens ativos; no check-out comandas abertas são fechadas (com itens) ou canceladas (sem itens)
- **Admin**: pode editar `total_value` e `observation` pós-checkout (para extras)

## Seed Data

```bash
rails db:seed
```
- Usuários: `admin@admin.com` / `123456` (admin), `atendente@admin.com` / `123456` (atendente)
- Quartos: 7, 8, 9, 10 (andar 1)
- PricePeriods: 4 períodos fixos acima

## Rotas

```
get "comandas"   → tabs#dashboard   (Central de Comandas)
get "relatorios" → tabs#report      (Faturamento do bar)

resources :rooms do
  member do
    patch :start_cleaning; patch :finish_cleaning; patch :release_quarantine
    get :history
  end
  resources :tabs do
    member { patch :close, :pay, :cancel, :transfer, :apply_discount }
    collection { post :create_walk_in }
    resources :tab_items do member { patch :void, :update_quantity } end
  end
end

resources :stays do
  member { patch :check_out; patch :cancel; get :info }
end

root: autenticado → stays#index, não autenticado → home#index
```

Rotas de `tabs`/`tab_items` são aninhadas em `rooms`, gerando helpers como
`room_tab_path(room, tab)`, `room_tab_tab_items_path(room, tab)`,
`void_room_tab_tab_item_path(room, tab, item)` e `update_quantity_room_tab_tab_item_path(room, tab, item)`.

## Políticas (Pundit)

- `StayPolicy` — `create?/update?/cancel?/check_out?` → admin ou attendant; `destroy?` → admin; `index?/show?` → autenticado
- `RoomPolicy` — `create?/update?/destroy?` → admin; `start_cleaning?/finish_cleaning?/release_quarantine?` → admin ou attendant; `index?/show?/history?` → autenticado
- `TabPolicy`/`TabItemPolicy`/`ProductPolicy` — operações de comanda → admin ou attendant (`cancel?`/`destroy?` → apenas admin)

## Pipeline CI (`.github/workflows/ci.yml`)

Roda em PR/push para main:
1. `scan_ruby` — brakeman + bundler-audit
2. `scan_js` — importmap audit
3. `lint` — rubocop (com cache)
4. `test` — testes unitários (PostgreSQL)
5. `system-test` — testes de sistema (PostgreSQL, screenshots em falha)

## Pegadinhas

- Atendente **deve redigitar senha** no check-in (validado em `StaysController#create`)
- Status do quarto: `occupied` no check-in; no check-out vira **`dirty`** (entra no ciclo de limpeza, não volta direto para `available`); no cancelamento volta para `available`. Toda troca de status gera `RoomStatusLog` automaticamente via `RoomAuditable`
- `RoomStatusLog#from_status`/`to_status` são inteiros com enum baseado em `Room.statuses` — atribuir string direto sem o enum coagia tudo para `0`
- `CleaningLog` usa enum `started/finished/approved/rejected`; `cleaned_by` é `belongs_to` obrigatório (definido no check-out e atualizado em `finish!`)
- Stay `status` enum: `active` (0), `completed` (1), `cancelled` (2)
- Room `status` enum: `available` (0), `occupied` (1), `dirty` (2), `cleaning` (3), `quarantine` (4), `maintenance` (5) — com `prefix: true` (ex.: `status_available?`)
- Comandas vazias (sem itens) não podem ser `close!` (`Tabs::CloseService` exige itens) — no check-out são canceladas
- Locale: apenas pt-BR (formatos data/hora, traduções models/atributos)
- Usa `solid_cache`, `solid_queue`, `solid_cable` (backed by DB, sem Redis)
- Kamal configurado para deploy Docker (`.kamal/`)