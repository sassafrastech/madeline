# == Schema Information
#
# Table name: media
#
#  created_at            :datetime         not null
#  id                    :integer          not null, primary key
#  item                  :string
#  item_content_type     :string
#  item_file_size        :integer
#  item_height           :integer
#  item_width            :integer
#  kind_value            :string
#  media_attachable_id   :integer
#  media_attachable_type :string
#  sort_order            :integer
#  updated_at            :datetime         not null
#  uploader_id           :integer
#
# Indexes
#
#  index_media_on_media_attachable_type_and_media_attachable_id  (media_attachable_type,media_attachable_id)
#
# Foreign Keys
#
#  fk_rails_...  (uploader_id => people.id)
#

class Media < ApplicationRecord
  include Translatable
  include OptionSettable

  belongs_to :media_attachable, polymorphic: true
  belongs_to :uploader, class_name: 'Person'

  mount_uploader :item, MediaItemUploader

  validates :item, :kind_value, presence: true
  validate :update_item_error

  translates :caption, :description

  delegate :division, :division=, to: :media_attachable

  scope :images_only, -> { where(kind_value: 'image') }

  # Beware, the methods generated by this include will fail
  # without the corresponding OptionSet records existing in the database.
  attr_option_settable :kind

  after_commit :recalculate_loan_health

  def alt
    self.try(:caption) || self.media_attachable.try(:name)
  end

  def thumbnail?
    kind_value == "image" && item_content_type.include?("image")
  end

  def recalculate_loan_health
    # Only submit a job if it is a Loan
    RecalculateLoanHealthJob.perform_later(loan_id: media_attachable_id) if media_attachable_type == 'Project'
  end

  def visual?
    %w(image video).include?(kind_value)
  end

  private

  # checks if there is an error that is not caused be the image being empty
  def error_but_not_item_error?
    if errors.messages
      errors.messages.count == 1 && (errors.messages[:kind_value] == ["can't be blank"])
    end
  end

  # a hack to request re-attaching the image when the form re-renders since
  # there is no clear way to re-render the image when using AJAX
  def update_item_error
    errors.add(:item, :reattach) if error_but_not_item_error?
  end
end
