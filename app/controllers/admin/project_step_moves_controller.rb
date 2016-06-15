class Admin::ProjectStepMovesController < Admin::AdminController
  include TranslationSaveable, LogControllable

  def new
    @step = ProjectStep.find(params[:step_id])
    authorize @step, :update?
    @step_move = ProjectStepMove.new(step: @step)
    set_log_form_vars
    @log = ProjectLog.new(project_step_id: params[:step_id])
    @context = params[:context]
    render layout: false
  end

  def create
    @step = ProjectStep.find(params[:project_log][:project_step_id])
    authorize @step, :update?
    @log = ProjectLog.new(project_log_attribs)
    authorize @log, :create?
    @step_move = ProjectStepMove.new(project_step_move_params.merge(step: @step))

    @log.save
    @step_move.execute!

    @expand_logs = true
    set_log_form_vars
    render partial: 'admin/project_steps/project_step', locals: {
      step: @step,
      context: 'timeline',
      mode: :show
    }
  end

  private

  def project_step_move_params
    params.require(:project_step_move).permit(:move_type, :shift_subsequent)
  end

  #
  # # Updates scheduled date of all project steps following this
  # def shift_subsequent
  #   @step = ProjectStep.find(params[:id])
  #   num_days = params[:num_days].to_i
  #   authorize @step
  #   ids = @step.subsequent_step_ids(@step.scheduled_date - num_days.days)
  #   unused, notice = batch_operation(ids){ |step| step.adjust_scheduled_date(num_days) }
  #   display_timeline(@step.project_id, notice)
  # end
end
