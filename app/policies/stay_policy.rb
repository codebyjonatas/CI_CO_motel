class StayPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.has_any_role? :admin, :attendant
  end

  def new?
    create?
  end

  def update?
    user.has_any_role? :admin, :attendant
  end

  def edit?
    update?
  end

  def cancel?
    user.has_any_role? :admin, :attendant
  end

  def destroy?
    user.has_role? :admin
  end
  def check_out?
    user.has_any_role? :admin, :attendant
  end
end
