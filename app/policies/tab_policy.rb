class TabPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.admin? || user.attendant?
  end

  def update?
    user.admin? || user.attendant?
  end

  def close?
    user.admin? || user.attendant?
  end

  def pay?
    user.admin? || user.attendant?
  end

  def cancel?
    user.admin?
  end

  def transfer?
    user.admin? || user.attendant?
  end

  def apply_discount?
    user.admin? || user.attendant?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
