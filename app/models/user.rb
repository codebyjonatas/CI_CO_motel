class User < ApplicationRecord
  rolify
  # Cadastro público desabilitado: usuários são criados por administradores.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  validates :name, presence: true

  def admin?
    has_role?(:admin)
  end

  def attendant?
    has_role?(:attendant)
  end

  def role
    roles.first&.name
  end

  def self.system_user
    find_or_create_by!(email: "system@motelflow.local") do |u|
      u.name = "Sistema"
      u.password = SecureRandom.hex(16)
    end
  end
end
