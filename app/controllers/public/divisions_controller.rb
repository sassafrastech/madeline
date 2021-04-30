class Public::DivisionsController < Public::PublicController
  layout 'public/main'

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def show
    @division = Division.find_by(short_name: params[:short_name])
    @selected_division = @division
    authorize @division
    # assume this division is public . ..
    # loan scope handles filtering loans based on whether their division is public, their status, and their public level value
    divisions_to_include = @division.self_and_descendants&.map(&:id)
    @loans = policy_scope(Loan.where(division: divisions_to_include)).page(params[:page]).per(5)
  end

  private

  def user_not_authorized
    flash[:error] = t('public.divisions.not_authorized')
  end
end
