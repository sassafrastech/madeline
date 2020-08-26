class Admin::DivisionsController < Admin::AdminController
  before_action :find_division, only: %i[show update destroy]

  def select
    redisplay_url = params[:redisplay_url] || root_path
    division_id = params[:division_id]
    save_selected_division_to_session(division_id)
    division = Division.find_safe(division_id)
    authorize division || current_division
    redirect_to redisplay_url
  end

  def index
    authorize Division
    @divisions_grid = initialize_grid(
      policy_scope(Division.where.not(parent: nil)),
      include: [:default_currency],
      conditions: index_filter,
      order: "name",
      per_page: 50,
      name: "divisions",
      enable_export_to_csv: true,
      custom_order: {
        "divisions.name" => "LOWER(divisions.name)",
        # Order by tree depth and then division name when ordering by parent.
        "parents_divisions.name" => "(SELECT MAX(generations) FROM division_hierarchies
          WHERE descendant_id = divisions.id), parents_divisions.name"
      }
    )

    @csv_mode = true
    @enable_export_to_csv = true

    export_grid_if_requested("divisions": "divisions_grid_definition") do
      # This block only executes if CSV is not being returned.
      @csv_mode = false
    end
  end

  # show view includes edit
  def show
    authorize @division
    prep_form_vars
  end

  def new
    @division = Division.new(parent: current_division)
    authorize @division
    prep_form_vars
  end

  def update
    authorize @division
    division_params = prep_division_params
    qb_department_id = division_params.delete(:qb_department_id)
    @division.update(division_params)
    @division.qb_department = ::Accounting::QB::Department.find(qb_department_id) if qb_department_id.present?
    if @division.save
      redirect_to admin_division_path(@division), notice: I18n.t(:notice_updated)
    else
      prep_form_vars
      render :show
    end
  end

  def create
    division_params = prep_division_params
    @division = Division.new(division_params)
    if @division.parent
      authorize @division
    else
      # Let record with missing parent bypass the policy check so a validation message will be
      # presented to the user, instead of fatal exception thrown.
      skip_authorization
    end

    if @division.save
      redirect_to admin_division_path(@division), notice: I18n.t(:notice_created)
    else
      prep_form_vars
      render :new
    end
  end

  def destroy
    authorize @division

    if @division.destroy
      redirect_to admin_divisions_path, notice: I18n.t(:notice_deleted)
    else
      prep_form_vars
      render :show
    end
  end

  private

  def prep_division_params
    params.require(:division).permit(:name, :description, :logo, :logo_text, :default_currency_id, :qb_department_id, :parent_id, :public,
      :banner_fg_color, :banner_bg_color, :short_name, :accent_main_color, :accent_fg_color, :notify_on_new_logs, locales: [])
  end

  def find_division
    @division = Division.find(params[:id])
  end

  def save_selected_division_to_session(id)
    id = nil if id.blank?
    session[:selected_division_id] = id
  end

  def index_filter
    selected = selected_division
    selected ? {id: selected.self_and_descendant_ids} : nil
  end

  def prep_form_vars
    @currency_choices = Currency.order(:name)
    @parent_choices = parent_choices(@division)
    @qb_department_choices = ::Accounting::QB::Department.order(:name)
  end

  # List of other divisions which the current user has access to and are allowed to be assigned
  # as a parent to this division.
  def parent_choices(division)
    (current_user.accessible_divisions - division.self_and_descendants) | [division.parent]
  end
end
