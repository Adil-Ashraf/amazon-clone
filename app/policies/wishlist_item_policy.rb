class WishlistItemPolicy < ApplicationPolicy
  def destroy?
    user.present? && record.user_id == user.id
  end
end
