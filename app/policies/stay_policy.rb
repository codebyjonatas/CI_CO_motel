class StayPolicy < ApplicationPolicy
  def index?
    staff?
  end

  def show?
    staff?
  end

  def create?
    staff?
  end

  def new?
    create?
  end

  def update?
    staff?
  end

  def edit?
    update?
  end

  def cancel?
    staff?
  end

  def check_out?
    staff?
  end

  def destroy?
    user&.admin?
  end
end
