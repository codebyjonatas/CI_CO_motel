# Resumo CI/CO Motel - Estado Atual (Fases 1-3.3 Concluídas)

## 📋 Visão Geral
Sistema Rails 8.1 para gestão de quartos de motel/hotel com check-in/out, comandas de bar, ciclo de limpeza e auditoria.

---

## ✅ Implementado

### **Fase 1 - Fundação (Models + Seeds)**
| Model | Descrição |
|-------|-----------|
| `Room` | Quarto com AASM: `available → occupied → dirty → cleaning → quarantine → maintenance` |
| `Stay` | Estadia (belongs_to Room, User, PricePeriod) |
| `User` | Devise + Rolify (`admin?`, `attendant?`, `role`) |
| `PricePeriod` | Períodos fixos (1h, 2h, pernoite básico/avançado) |
| `Product` | 18 produtos do bar (cerveja, destilados, refrigerantes, petiscos, água) |
| `ProductPriceRule` | Regras de preço dinâmico (Happy Hour 17-20h seg-sex, fim de semana, madrugada) |
| `Tab` | Comanda (enum: `open, closed, paid, cancelled, transferred`) |
| `TabItem` | Item da comanda (enum: `active, voided, transferred`) |
| `TabItemAudit` | Auditoria imutável de estornos/alterações |
| `RoomStatusLog` | Log de mudança de status do quarto |
| `StayGuest` | Hóspedes da estadia (main_guest unique) |
| `CleaningLog` | Log de limpeza (started, finished, approved, rejected) |

### **Fase 2 - Comanda Core (Services + Controllers + Views)**
| Componente | Arquivos |
|------------|----------|
| **Services** | 9 services: `Tabs::CreateService`, `CreateWalkInService`, `CloseService`, `PayService`, `CancelService`, `TransferService`, `TabItems::AddItemService`, `VoidService`, `UpdateQuantityService` |
| **Controllers** | `TabsController` (index, show, new, create, create_walk_in, close, pay, cancel, transfer, apply_discount), `TabItemsController` (create, void, update_quantity) |
| **Views** | `tabs/index` (lista por quarto), `tabs/show` (detalhe + modais), `tabs/new` (unificado estadia/passante) |
| **Policies** | `TabPolicy`, `TabItemPolicy`, `ProductPolicy` (admin/attendant) |
| **Helpers** | `TabsHelper` (badges de status) |
| **Rotas** | `resources :rooms { resources :tabs { member { patch :close, :pay, :cancel, :transfer, :apply_discount } collection { post :create_walk_in } resources :tab_items { member { patch :void, :update_quantity } } } }` |

### **Fase 3.1-3.3 - Ciclo de Limpeza**
- **Room AASM**: Estados expandidos + transições validadas (`check_in`, `check_out`, `start_cleaning`, `finish_cleaning`, `release_from_quarantine`, `to_maintenance`, `back_from_maintenance`)
- **RoomAvailabilityConcern**: Scopes inteligentes (`available_for_checkin`, `becoming_available_within`, `in_cleaning_cycle`, `dashboard_summary`)
- **RoomCleaningConfig**: Quarentena configurável via credentials (padrão 30min)
- **CleaningLog**: Auditoria completa (started → finished → approved/rejected)
- **Views Rooms**: Botão "Comandas" no index/show + alert de comanda ativa

---

## ⚙️ Configuração (config/credentials.yml.enc)
```yaml
discount_limits:
  attendant_max_percent: 15
  attendant_max_absolute: 50.00
  admin_max_percent: 100
  admin_max_absolute: 999999.00

room_cleaning:
  quarantine_minutes: 30
```

---

## 🔗 Fluxos Principais

### Check-in → Comanda → Check-out
```
1. Stay.create! + room.check_in! → Room.occupied
2. Tab.create! (vinculada à stay) → Tab.open
3. TabItem.create! (produtos) → Tab.recalculate_totals!
4. Tab.close! / Tab.pay! → Tab.closed / Tab.paid
5. Stay.check_out! → Room.dirty + CleaningLog.started
```

### Ciclo de Limpeza
```
Room.dirty --start_cleaning!--> Room.cleaning --finish_cleaning!--> Room.quarantine (30min) --release_from_quarantine!--> Room.available
```

---

## ✅ Fase 3.4 - Fechamento & Relatórios (Concluída)

### 1. **Aba "Comandas" no Dashboard/Quartos** ✅
- Central de comandas (`/comandas`) com filtros por quarto/status/período e ações rápidas

### 2. Integração Check-out + Comanda ✅
- `Stays::CloseAccountService` - fecha/cancela comandas abertas no check-out
- `Stays::CheckOutService` - orquestra: fecha comandas → conclui estadia → quarto `dirty` + `CleaningLog.started`

### 3. Query Objects ✅
- `RoomHistoryQuery` - timeline completo do quarto (estadias + comandas + limpezas + status)
- `AvailableRoomsQuery` - quartos disponíveis (check-in) e aptos a nova comanda
- `TabReportQuery` - relatórios de faturamento do bar (por dia/quarto/atendente/produto)

### 4. Views de Limpeza ✅
- `RoomsController#history` - timeline unificada (stay + cleaning + status)
- `RoomsController#index` - cards de resumo operacional + grade de quartos
- Ações: `start_cleaning`, `finish_cleaning`, `release_quarantine` (+ botões no index/show)
- Página de relatórios: `/relatorios` (`tabs#report`)

---

## 🧪 Verificações de Qualidade
```bash
rails test           # ✅ Passando
bin/rubocop          # ✅ Zero offenses
bin/importmap audit  # ✅ Sem vulnerabilidades
```

---

## 📁 Estrutura de Pastas Relevante
```
app/
├── models/
│   ├── concerns/           # room_auditable, room_availability, room_cleaning_config, discount_limit
│   ├── room.rb             # + AASM
│   ├── stay.rb
│   ├── user.rb             # + admin?, attendant?
│   ├── product.rb
│   ├── product_price_rule.rb
│   ├── tab.rb
│   ├── tab_item.rb
│   ├── tab_item_audit.rb
│   ├── room_status_log.rb
│   ├── stay_guest.rb
│   └── cleaning_log.rb
├── services/
│   ├── tabs/               # 6 services
│   ├── tab_items/          # 3 services
│   └── stays/              # CloseAccountService, CheckOutService
├── queries/
│   ├── tab_dashboard_query.rb
│   ├── room_history_query.rb
│   ├── available_rooms_query.rb
│   └── tab_report_query.rb
├── controllers/
│   ├── tabs_controller.rb
│   ├── tab_items_controller.rb
│   ├── rooms_controller.rb
│   └── stays_controller.rb
├── views/
│   ├── tabs/               # index, show, new, dashboard, report
│   └── rooms/              # index (cards resumo), show, history (timeline)
├── policies/
│   ├── tab_policy.rb
│   ├── tab_item_policy.rb
│   └── product_policy.rb
└── helpers/
    └── tabs_helper.rb
```

---

## 🎯 Próximos Passos Sugeridos
- Unificar estratégia de auditoria de status (auto-log do `RoomAuditable` vs. logs manuais dos services)
- Testes de sistema (Capybara) para os fluxos de check-out e ciclo de limpeza
- Paginação/ordenação adicionais no dashboard de comandas (ex.: "abertas há > 4h")
