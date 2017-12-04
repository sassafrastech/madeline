class Admin::NotesController < Admin::AdminController
  before_action :set_note, only: [:update, :destroy]

  def create
    @note = Note.new(note_params.merge author: current_user.profile)
    authorize @note

    if @note.save
      render partial: 'note', locals: { note: @note }
    else
      render partial: 'form', status: :unprocessable_entity, locals: { note: @note }
    end
  end

  def update
    if @note.update(note_params)
      render partial: 'note', locals: { note: @note }
    else
      render partial: 'form', status: :unprocessable_entity, locals: { note: @note }
    end
  end

  def destroy
    @note.destroy
    head :ok
  end

  private

  def set_note
    @note = Note.find(params[:id])
    authorize @note
  end

  def note_params
    params.require(:note).permit(:text, :notable_id, :notable_type)
  end
end
