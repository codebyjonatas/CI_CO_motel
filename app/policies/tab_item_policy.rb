class TabItemPolicy < ApplicationPolicy
  def create?
    user.admin? || user.attendant?
  end

  def update?
    user.admin? || user.attendant?
  end

  def void?
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
