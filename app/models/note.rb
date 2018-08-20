# == Schema Information
#
# Table name: notes
#
#  author_id    :integer
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  notable_id   :integer
#  notable_type :string
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_notes_on_author_id                    (author_id)
#  index_notes_on_notable_type_and_notable_id  (notable_type,notable_id)
#

class Note < ApplicationRecord
  include ::Translatable

  belongs_to :notable, polymorphic: true
  belongs_to :author, class_name: 'Person'

  delegate :division, :division=, to: :notable
  delegate :name, to: :author, prefix: true

  # define accessor like convenience methods for the fields stored in the Translations table
  attr_translatable :text

  validates :notable, presence: true
  validates :author, presence: true

  def name
    "#{notable.try(:name)} note"
  end

end
