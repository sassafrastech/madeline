class LoanPolicy < ProjectPolicy
  def show?
    if user # madeline, so use divisionowned
      super
    else # public pages, so don't use divisionowned
      record.public_level_value != "hidden" &&
        %w(active completed).include?(record.status_value) &&
        record.division.public
    end
  end

  class Scope < DivisionOwnedScope
    def resolve
      if user # madeline, so use divisionowned
        super
      else # public pages, so don't use divisionowned
        publicly_visible(scope)
      end
    end

    def publicly_visible(scope)
      public_division_ids = Division.where(public: true).pluck(:id)
      scope.where(division: public_division_ids).active_or_completed.where.not(public_level_value: "hidden")
    end
  end
end
