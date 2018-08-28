# == Schema Information
#
# Table name: timeline_entries
#
#  actual_end_date         :date
#  agent_id                :integer
#  created_at              :datetime         not null
#  date_change_count       :integer          default(0), not null
#  finalized_at            :datetime
#  id                      :integer          not null, primary key
#  is_finalized            :boolean
#  old_duration_days       :integer          default(0)
#  old_start_date          :date
#  parent_id               :integer
#  project_id              :integer
#  schedule_parent_id      :integer
#  scheduled_duration_days :integer
#  scheduled_start_date    :date
#  step_type_value         :string           not null
#  type                    :string           not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_timeline_entries_on_agent_id    (agent_id)
#  index_timeline_entries_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => people.id)
#  fk_rails_...  (parent_id => timeline_entries.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (schedule_parent_id => timeline_entries.id)
#

class TimelineEntry < ApplicationRecord
  include Translatable, OptionSettable

  has_closure_tree

  attr_translatable :summary

  belongs_to :project, inverse_of: :timeline_entries
  belongs_to :agent, class_name: 'Person'

  # Even though, logs can only be associated with steps, this ass'n is defined here so that
  # Project can do has_many :project_logs, through: :timeline_entries
  has_many :project_logs, dependent: :destroy, foreign_key: :project_step_id

  delegate :division, :division=, to: :project, allow_nil: true

  # NOTE: This will only work for steps, but must be defined here in the parent class.
  # It DOES NOT do the nice recursive date stuff that group.filtered_children does.
  scope :by_date, -> {
    order("scheduled_start_date IS NULL, scheduled_start_date, scheduled_duration_days, id") }

  amoeba do
    enable
    propagate
    include_association :translations
    include_association :project_logs
    nullify :schedule_parent_id
  end

  # Returns a value that can be used in sort operations. Should be analogous to the by_date scope above, but
  # for use with in-memory sorts.
  def sort_key
    @sort_key ||= [scheduled_start_date.nil? ? 1 : 0, scheduled_start_date || 0, scheduled_duration_days || 0, id]
  end

  def step?
    is_a?(ProjectStep)
  end

  def group?
    is_a?(ProjectGroup)
  end
end
