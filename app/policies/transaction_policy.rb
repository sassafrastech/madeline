class TransactionPolicy < ApplicationPolicy
  def index?
    division_admin(division: Division.root)
  end
end
