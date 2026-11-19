class TabItemPolicy < ApplicationPolicy
  def create?
    staff?
  end

  def update?
    staff?
  end

  def void?
    staff?
  end

  def destroy?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
