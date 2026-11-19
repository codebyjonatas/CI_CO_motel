class TabPolicy < ApplicationPolicy
  def index?
    staff?
  end

  # O quarto vem da URL (TabsController#set_current_room), nunca do próprio
  # registro, para que a checagem não seja tautológica.
  def show?
    staff? && record.room_id == Current.room&.id
  end

  def create?
    staff?
  end

  def update?
    staff?
  end

  def close?
    staff?
  end

  def pay?
    staff?
  end

  def cancel?
    user&.admin?
  end

  def transfer?
    staff?
  end

  def apply_discount?
    staff?
  end

  def destroy?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      # Usuários só veem comandas dos quartos que têm acesso na requisição atual
      if Current.room.present?
        scope.where(room_id: Current.room.id)
      else
        scope.none
      end
    end
  end
end
