class RoomPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.has_role? :admin
  end

  def new?
    create?
  end

  def update?
    user.has_role? :admin
  end

  def edit?
    update?
  end

  def destroy?
    user.has_role? :admin
  end

  def start_cleaning?
    manage_cleaning?
  end

  def finish_cleaning?
    manage_cleaning?
  end

  def release_quarantine?
    manage_cleaning?
  end

  def history?
    true
  end

  private

  def manage_cleaning?
    user.has_any_role? :admin, :attendant
  end
end
