# == Schema Information
#
# Table name: projects
#
#  actual_end_date                       :date
#  actual_first_interest_payment_date    :date
#  actual_first_payment_date             :date
#  actual_return                         :decimal(, )
#  amount                                :decimal(, )
#  created_at                            :datetime         not null
#  currency_id                           :integer
#  custom_data                           :json
#  division_id                           :integer          not null
#  id                                    :integer          not null, primary key
#  length_months                         :integer
#  loan_type_value                       :string
#  name                                  :string
#  organization_id                       :integer
#  original_id                           :integer
#  primary_agent_id                      :integer
#  projected_end_date                    :date
#  projected_first_interest_payment_date :date
#  projected_first_payment_date          :date
#  projected_return                      :decimal(, )
#  public_level_value                    :string           not null
#  rate                                  :decimal(, )
#  representative_id                     :integer
#  secondary_agent_id                    :integer
#  signing_date                          :date
#  status_value                          :string
#  txn_handling_mode                     :string           default("automatic"), not null
#  type                                  :string           not null
#  updated_at                            :datetime         not null
#
# Indexes
#
#  index_projects_on_currency_id      (currency_id)
#  index_projects_on_division_id      (division_id)
#  index_projects_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (currency_id => currencies.id)
#  fk_rails_...  (division_id => divisions.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (primary_agent_id => people.id)
#  fk_rails_...  (representative_id => people.id)
#  fk_rails_...  (secondary_agent_id => people.id)
#

class Project < ApplicationRecord
  include Translatable
  include OptionSettable

  before_destroy :allow_destroy

  # Status values can be found at Loan.status_option_set.options and
  # BasicProject.status_option_set.options
  OPEN_STATUSES = %w(active changed possible prospective).freeze

  belongs_to :division
  belongs_to :primary_agent, class_name: "Person"
  belongs_to :secondary_agent, class_name: "Person"
  belongs_to :original, class_name: "Project"
  has_many :timeline_entries, dependent: :destroy
  has_many :project_logs, through: :timeline_entries
  has_many :transactions, class_name: "Accounting::Transaction", dependent: :destroy
  has_many :copies, class_name: "Project", foreign_key: "original_id", dependent: :nullify
  has_many :problem_loan_transactions, class_name: "Accounting::ProblemLoanTransaction", dependent: :destroy

  scope :visible, -> { where.not(public_level_value: "hidden") }

  # define accessor-like convenience methods for the fields stored in the Translations table
  translates :summary, :details
  attr_accessor :destroying

  validate :check_agents
  validates :division_id, presence: true

  alias_method :logs, :project_logs

  delegate :qb_division, to: :division

  # Configure how the class is duplicated
  amoeba do
    enable
    propagate
    exclude_association :media
    exclude_association :timeline_entries
    exclude_association :transactions
    exclude_association :copies
    exclude_association :problem_loan_transactions

    # The default name is computed, if it hasn't been set it will be blank.
    # We need to manually copy over the name and set it here for it to work.
    customize(lambda { |orig, new|
      new.name = "Copy of #{orig.display_name}"
    })
  end

  # The Loan's timeline entries should be accessed via this root node.
  # Timeline steps are organzed as a tree. The tree has a blank root node (ProjectGroup) that is not shown
  # to the user, but makes it easier to do computations over the tree (instead of each top level group
  # being the root of its own separate tree).
  # May return nil if there are no groups or steps in the loan thus far.
  def root_timeline_entry
    @root_timeline_entry ||= timeline_entries.find_or_create_by(parent_id: nil, type: "ProjectGroup")
  end

  def timeline_groups_preordered
    root_timeline_entry.self_and_descendant_groups_preordered
  end

  # DEPRECATED - This should not be necessary once we transition to tabular format.
  # Do regular ruby select, to avoid issues with AR caching
  # Note, this means the method returns an array, not an AR::Relation
  def project_steps
    timeline_entries.order(:scheduled_start_date).select { |e| e.type == "ProjectStep" }
  end

  def display_name
    return "" if new_record?
    name.blank? ? default_name : name
  end

  def agent_names
    [primary_agent.try(:name), secondary_agent.try(:name)].compact
  end

  def display_agent_names
    agent_names.join(", ")
  end

  def calendar_events
    CalendarEvent.build_for(self)
  end

  def project_events(order_by = "Completed IS NULL OR Completed = '0000-00-00', Completed, Date")
    @project_events ||= ProjectEvent.includes(project_logs: :progress_metric).
      where("LOWER(ProjectTable) = 'projects' and ProjectID = ?", self.ID).order(order_by)
    @project_events.reject do |p|
      # Hide past uncompleted project events without logs (for now)
      !p.completed && p.project_logs.empty? && p.date <= Time.zone.today
    end
  end

  def health_status_available?
    false
  end

  def self.dashboard_order(person_id)
    clauses = []

    clauses << Arel.sql("CASE WHEN projects.primary_agent_id = #{person_id} THEN 1"\
                    "WHEN projects.secondary_agent_id = #{person_id} THEN 2 END")

    clauses << Arel.sql("CASE projects.status_value WHEN 'active' THEN 1 WHEN 'prospective'"\
                    "THEN 2 ELSE 3 END")

    clauses << Arel.sql("CASE projects.type WHEN 'Loan' THEN 1 WHEN 'BasicProject' THEN 2 END")

    clauses.join(", ")
  end

  private

  def agents_the_same?
    (primary_agent.present? || secondary_agent.present?) && (primary_agent == secondary_agent)
  end

  def check_agents
    errors.add(:primary_agent, :same_as_secondary) if agents_the_same?
  end

  def allow_destroy
    self.destroying = true
  end
end
