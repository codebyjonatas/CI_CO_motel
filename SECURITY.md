# Política de Segurança — MotelFlow

Documento operacional: **o que guardar, onde guardar, como rotacionar**.
Fonte da verdade dos segredos: **Bitwarden** (pasta `MotelFlow`).

---

## 1. Princípios

1. **Nenhum segredo no repositório.** Só `.env.example` (modelo, sem valores) e `.kamal/secrets` (que apenas referencia variáveis).
2. **Um segredo, um lugar.** O Bitwarden é a fonte da verdade; `.env.local` é cache derivado e descartável.
3. **Menor privilégio.** Credencial de dev nunca abre produção; credencial de produção nunca vai para a máquina do dev.
4. **Rotação é rotina, não emergência.** Trocar antes de vencer, não depois de vazar.
5. **Nada de segredo em histórico de shell, log, screenshot ou ticket.**

---

## 2. Estrutura no Bitwarden

Pasta: **`MotelFlow`** (vault pessoal enquanto o time for pequeno; migrar para Organization quando houver mais de uma pessoa com acesso a produção).

Convenção de nome: `MotelFlow | <Assunto> (<ambiente>)`.
O prefixo evita colisão com itens pessoais e permite que os scripts localizem o item por nome exato.

### 2.1 Itens obrigatórios

| Item | Tipo | Campo | Conteúdo | Consumido por |
|------|------|-------|----------|---------------|
| `MotelFlow \| Rails Master Key (dev)` | Login | `password` | Conteúdo de `config/master.key` (32 hex) | `bin/setup-env` → `RAILS_MASTER_KEY` |
| `MotelFlow \| Rails Master Key (prod)` | Login | `password` | Master key de produção (32 hex) | `bin/kamal-with-secrets` |
| `MotelFlow \| Database (dev)` | Login | `username` / `password` | Usuário e senha do PostgreSQL local | `bin/setup-env` → `DATABASE_URL` |
| `MotelFlow \| Database (prod)` | Login | `username` / `password` | `sys_check_in_check_out` + senha forte | `bin/kamal-with-secrets` → `SYS_CHECK_IN_CHECK_OUT_DATABASE_PASSWORD` |
| `MotelFlow \| App Config (prod)` | Nota segura | custom fields | ver 2.2 | `bin/kamal-with-secrets` |

**Custom fields do item `Database (dev)` / `Database (prod)`:**

| Field | Exemplo |
|-------|---------|
| `host` | `localhost` / `db.interno` |
| `port` | `5432` |
| `database` | `sys_check_in_check_out_development` / `sys_check_in_check_out_production` |

> No dev, se o PostgreSQL usa autenticação por socket/peer, deixe `password` vazio e omita `host`. O `bin/setup-env` então não gera `DATABASE_URL` (e avisa).

### 2.2 Custom fields do `App Config (prod)`

| Field | Exemplo | Obrigatório |
|-------|---------|-------------|
| `APP_HOST` | `motel.exemplo.com` | sim |
| `SEED_ADMIN_PASSWORD` | senha forte (≥ 16 chars) | só se rodar `db:seed` em prod |
| `SEED_ATTENDANT_PASSWORD` | senha forte (≥ 16 chars) | só se rodar `db:seed` em prod |
| `DISCOUNT_LIMITS_ADMIN_MAX_PERCENT` | `100` | não (default 100) |
| `DISCOUNT_LIMITS_ADMIN_MAX_ABSOLUTE` | `1000` | não (default infinito) |
| `DISCOUNT_LIMITS_ATTENDANT_MAX_PERCENT` | `15` | não (default 15) |
| `DISCOUNT_LIMITS_ATTENDANT_MAX_ABSOLUTE` | `50` | não (default 50) |
| `ROOM_CLEANING_QUARANTINE_MINUTES` | `30` | não (default 30) |

### 2.3 Itens opcionais

| Item | Tipo | Uso |
|------|------|-----|
| `MotelFlow \| SMTP` | Login (`username`/`password`) + fields `address`, `port` | Envio de e-mail (Devise: reset de senha, confirmação) |
| `MotelFlow \| Kamal Registry` | Login (`username`/`password`) | Só quando o registry exigir autenticação (hoje `localhost:5555`) |

### 2.4 O que **não** guardar no Bitwarden do projeto

- Senhas pessoais de atendentes/admin do sistema (ficam no Bitwarden de cada pessoa, ou são definidas no primeiro acesso).
- `config/master.key` versionado em qualquer lugar.
- Dumps de banco, backups, `.env.local` em anexo.

---

## 3. Fluxo do dia a dia

### 3.1 Primeira configuração (dev)

```bash
# 1. Instalar a CLI do Bitwarden
#    Linux:  sudo snap install bitwarden-cli
#    macOS:  brew install bitwarden-cli
#    Docs:   https://bitwarden.com/help/cli/

# 2. Autenticar
bw login

# 3. Conferir se os itens existem (não escreve nada)
bin/setup-env --check

# 4. Gerar .env.local
bin/setup-env

# 5. Ativar direnv (carrega .env.local ao entrar na pasta)
direnv allow

# 6. Subir a aplicação
bin/dev
```

### 3.2 Rotina

```bash
bin/setup-env          # ao trocar de máquina, ao rotacionar a master key
direnv reload          # após editar .env.local
```

O `.env.local` é `chmod 600` e está coberto por `/.env*` no `.gitignore`.

### 3.3 Deploy

```bash
# Segredos de produção são lidos do Bitwarden e injetados só no processo do Kamal.
bin/kamal-with-secrets deploy
bin/kamal-with-secrets app logs -f
```

Nada é gravado em disco. O `.kamal/secrets` apenas repassa as variáveis já exportadas.

### 3.4 CI/CD (GitHub Actions)

O workflow `.github/workflows/deploy.yml` usa API key do Bitwarden (`BW_CLIENTID`, `BW_CLIENTSECRET`, `BW_PASSWORD`) guardadas em **GitHub Environment `production`**. Ver seção 6.

---

## 4. Rotação de credenciais

| Credencial | Frequência | Janela |
|------------|-----------|--------|
| `RAILS_MASTER_KEY` | 90 dias e após qualquer suspeita | manutenção |
| Senha do PostgreSQL (prod) | 90 dias | sem downtime (rolling) |
| Senha SMTP | 90 dias ou troca de provedor | sem downtime |
| Senhas de seed | ao criar/remover usuários iniciais | — |
| API key do Bitwarden (CI) | 180 dias | — |

### 4.1 `RAILS_MASTER_KEY`

```bash
# 1. Backup do credentials atual
cp config/credentials.yml.enc /tmp/credentials.$(date +%F).enc

# 2. Editar (gera novo master.key se você remover o antigo antes)
bin/rails credentials:edit

# 3. Atualizar o item no Bitwarden:
#    "MotelFlow | Rails Master Key (prod)" (e "(dev)" se aplicável)

# 4. Regerar o .env.local local
bin/setup-env --force

# 5. Publicar em produção
bin/kamal-with-secrets deploy
```

> Trocar a master key invalida tokens derivados dela (reset de senha, confirmação, remember-me). Avise os usuários e faça em janela de manutenção.

### 4.2 Senha do PostgreSQL (prod)

```sql
ALTER USER sys_check_in_check_out WITH PASSWORD '<nova-senha-forte>';
```

1. Atualizar `MotelFlow | Database (prod)` no Bitwarden.
2. `bin/kamal-with-secrets deploy` (o container reinicia com a nova senha).

> Se houver réplicas/leitores, atualize todos antes do restart.

### 4.3 SMTP

1. Rotacionar no provedor (SendGrid/SES/etc.).
2. Atualizar `MotelFlow | SMTP`.
3. `bin/kamal-with-secrets deploy`.

---

## 5. Resposta a incidente (segredo vazado)

1. **Conter:** revogar/rotacionar o segredo imediatamente (seção 4).
2. **Erradicar:** remover do local exposto (commit, log, artefato, mensagem).
3. **Se foi commitado:**
   ```bash
   # Remover do histórico (requer force-push coordenado)
   git filter-repo --path config/master.key --invert-paths
   # ou, para string em arquivo:
   git filter-repo --replace-text <(echo 'SEGREDO_VAZADO==>***REMOVED***')
   ```
   Rotacione **mesmo que o commit tenha sido revertido** — o histórico pode ter sido copiado.
4. **Avaliar impacto:** logs de acesso do banco, do provedor SMTP, do registry, do servidor.
5. **Registrar:** data, segredo afetado, causa raiz, ações, responsável.
6. **Prevenir:** adicionar regra no gitleaks / teste que cubra o caso.

### Checklist rápido

- [ ] Segredo rotacionado no provedor de origem
- [ ] Item atualizado no Bitwarden
- [ ] Deploy feito com o novo valor
- [ ] Segredo antigo confirmado como inválido
- [ ] Histórico do git limpo (se aplicável)
- [ ] Post-mortem escrito

---

## 6. CI/CD — API key do Bitwarden

1. No Bitwarden: **Settings → Security → Keys → View API Key** (`client_id`, `client_secret`).
2. No GitHub: **Settings → Environments → production → Secrets**:
   - `BW_CLIENTID`
   - `BW_CLIENTSECRET`
   - `BW_PASSWORD` (senha mestra; use uma conta dedicada de automação se possível)
3. O workflow faz `bw login --apikey`, desbloqueia, lê os itens e exporta apenas o necessário para o job de deploy.

> Enquanto não houver servidor de produção, o workflow fica manual (`workflow_dispatch`) e pode ser ignorado.

---

## 7. Prevenção de vazamento local

Instale o gitleaks como hook de pre-commit:

```bash
# Linux/macOS
brew install gitleaks   # ou baixe o binário oficial

cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
gitleaks protect --staged --redact --no-banner
EOF
chmod +x .git/hooks/pre-commit
```

O CI também roda `gitleaks` (ver `.github/workflows/ci.yml` quando habilitado).

---

## 8. Checklist de revisão antes de cada deploy

- [ ] `bin/brakeman` sem novos avisos
- [ ] `bin/bundler-audit` sem vulnerabilidades
- [ ] `bin/importmap audit` limpo
- [ ] `bin/rails test` e `bin/rails test:system` verdes
- [ ] Nenhum segredo em `git diff --staged`
- [ ] `.env.local` e `config/master.key` fora do stage
- [ ] Migrações revisadas (sem `DROP` inesperado)
- [ ] Backup do banco de produção recente
