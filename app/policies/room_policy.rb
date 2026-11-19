class RoomPolicy < ApplicationPolicy
  def index?
    staff?
  end

  def show?
    staff?
  end

  def create?
    user&.admin?
  end

  def new?
    create?
  end

  def update?
    user&.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  def start_cleaning?
    staff?
  end

  def finish_cleaning?
    staff?
  end

  def release_quarantine?
    staff?
  end

  def history?
    staff?
  end
end
