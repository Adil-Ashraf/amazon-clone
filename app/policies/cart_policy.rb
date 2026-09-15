class CartPolicy < ApplicationPolicy
  def show?
    owner?
  end

  def update?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end
end
