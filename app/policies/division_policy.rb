class DivisionPolicy < ApplicationPolicy
  def index?
    # Require admin role on at least one division to allow access to index view
    any_division_admin?
  end

  def show?
    user ? division_member_or_admin(division: @record) : @record.public
  end

  def create?
    division_admin(division: @record.parent)
  end

  def update?
    division_admin(division: @record) &&
      !@record.root? # Root division is considered read-only.
  end

  # Note, for now we disallow deletion of divisions which have any organizations, loans, people,
  # or child divisions.  Can change later if needed to allow the ability to delete with all
  # dependencies.
  # Also, for now, restricting destroy permission to admins of the parent division.
  def destroy?
    !@record.root? &&
      division_admin(division: @record.parent) &&
      !@record.has_noncascading_dependents?
  end

  def select?
    show?
  end

  class Scope < Scope
    def resolve
      if user
        resolve_admin
      else
        resolve_public
      end
    end

    def resolve_admin
      scope.where(id: user.accessible_division_ids)
    end

    def resolve_public
      scope.published
    end

    def accessible_divisions(public_only: false)
      if public_only
        resolve_public
      else
        resolve_admin
      end
    end
  end
end
