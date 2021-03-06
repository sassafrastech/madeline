class DivisionPolicy < ApplicationPolicy
  def index?
    # Require admin role on at least one division to allow access to index view
    any_division_admin?
  end

  def show?
    division_member_or_admin(division: @record)
  end

  def create?
    division_admin(division: @record.parent)
  end

  def update?
    division_admin(division: @record) &&
      !@record.root?  # Root division is considered read-only.
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
      user ? scope.where(id: accessible_ids) : scope.published
    end

    # This merges in child divisions of the divisions for which a user has been specifically
    # granted access.
    def accessible_ids
      all_ids = base_accessible_ids.map do |id|
        division = Division.find_safe(id)
        division.self_and_descendants.pluck(:id) if division
      end
      all_ids.flatten.uniq.compact
    end

    # List of division hierarchy nodes for which user has been granted access.
    def base_accessible_ids
      user.roles.where(resource_type: :Division, name: [:member, :admin]).pluck(:resource_id).uniq
    end

    def accessible_divisions(public_only: false)
      public_only ? Division.published : user.accessible_divisions
    end
  end
end
