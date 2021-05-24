module Notable
  extend ActiveSupport::Concern     ## consider using SuperModule

  included do
    # notes that are added to organizations or people
    has_many :notes, as: :notable, dependent: :destroy
  end

  def add_note(text, author)
    note = notes.create(notable: self, author: author, text: text)
  end

end
