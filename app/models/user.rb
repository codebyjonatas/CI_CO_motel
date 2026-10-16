class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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
    find_or_create_by!(email: "system@ci-co-motel.local") do |u|
      u.name = "Sistema"
      u.password = SecureRandom.hex(16)
    end
  end
end
