# frozen_string_literal: true

# Configuração de Rate Limiting e Proteção contra Abuso
# Documentação: https://github.com/rack/rack-attack

class Rack::Attack
  # Rate limiting é comportamento de produção; nos testes ele derrubaria a
  # suíte após 5 logins da mesma "IP" (RackTest).
  Rack::Attack.enabled = !Rails.env.test?

  # Usa cache do Rails (Solid Cache) para armazenar contadores.
  # Em test usamos memória: o banco de teste não carrega as tabelas do Solid Cache.
  Rack::Attack.cache.store =
    if Rails.env.test?
      ActiveSupport::Cache.lookup_store(:memory_store)
    else
      ActiveSupport::Cache.lookup_store(:solid_cache_store)
    end

  # === THROTTLES (Limitação de taxa) ===

  # Login: 5 tentativas por 15 min por IP
  throttle("login/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Login: 10 tentativas por 15 min por email (previne enumeração)
  throttle("login/email", limit: 10, period: 15.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase
    end
  end

  # Check-in: 5 tentativas por 15 min por IP (protege reentrada de senha)
  throttle("checkin/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/stays" && req.post?
  end

  # Check-in: 3 tentativas por 15 min por usuário autenticado (previne brute force de senha)
  throttle("checkin/user", limit: 3, period: 15.minutes) do |req|
    if req.path == "/stays" && req.post? && req.env["warden"]&.user
      req.env["warden"].user.id
    end
  end

  # Password reset: 3 requests por hora por IP
  throttle("password_reset/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # API endpoints gerais: 100 req/min por usuário autenticado
  throttle("api/user", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/api/") && req.env["warden"]&.user
      req.env["warden"].user.id
    end
  end

  # === BLOCKLISTS (Bloqueio imediato) ===

  # Bloqueia IPs conhecidos como maliciosos (ex.: lista AbuseIPDB, Fail2Ban)
  # blocklist("blocked_ips") do |req|
  #   Rails.cache.read("blocked_ips:#{req.ip}").present?
  # end

  # Bloqueia requests com User-Agent suspeito (bots/scanners básicos)
  blocklist("bad_user_agents") do |req|
    ua = req.user_agent.to_s.downcase
    %w[sqlmap nikto nessus openvas w3af zap].any? { |bad| ua.include?(bad) }
  end

  # === SAFELISTS (Permite sempre) ===

  # Health check sempre permitido (load balancer, k8s probes)
  safelist("health_check") do |req|
    req.path == "/up"
  end

  # Assets e CSP report endpoint
  safelist("assets") do |req|
    req.path.start_with?("/assets/") || req.path == "/csp-violation-report-endpoint"
  end

  # === RESPOSTAS CUSTOMIZADAS ===

  # Resposta padrão para throttle (429 Too Many Requests)
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"]&.dig(:period) || 900)
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { error: "Muitas requisições. Tente novamente em #{retry_after} segundos.", retry_after: retry_after }.to_json ]
    ]
  end

  # Resposta para blocklist (403 Forbidden)
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { error: "Acesso negado." }.to_json ]
    ]
  end

  # === TRACKERS (Monitoramento) ===

  # Track de IPs fazendo login (para alertas)
  track("login_track/ip") do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Log de throttles para auditoria
  ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    if req.env["rack.attack.match_type"] == :throttle
      Rails.logger.warn "[Rack::Attack] Throttled: #{req.env["rack.attack.matched"]} from #{req.ip} - #{req.request_method} #{req.fullpath}"
    elsif req.env["rack.attack.match_type"] == :blocklist
      Rails.logger.warn "[Rack::Attack] Blocklisted: #{req.env["rack.attack.matched"]} from #{req.ip} - #{req.request_method} #{req.fullpath}"
    end
  end
end
