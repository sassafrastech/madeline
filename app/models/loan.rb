# == Schema Information
#
# Table name: loans
#
#  amount                      :decimal(, )
#  created_at                  :datetime         not null
#  currency_id                 :integer
#  custom_data                 :json
#  division_id                 :integer
#  first_interest_payment_date :date
#  first_payment_date          :date
#  id                          :integer          not null, primary key
#  length_months               :integer
#  loan_type_value             :string
#  name                        :string
#  organization_id             :integer
#  primary_agent_id            :integer
#  project_type_value          :string
#  projected_return            :decimal(, )
#  public_level_value          :string
#  rate                        :decimal(, )
#  representative_id           :integer
#  secondary_agent_id          :integer
#  signing_date                :date
#  status_value                :string
#  target_end_date             :date
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_loans_on_currency_id      (currency_id)
#  index_loans_on_division_id      (division_id)
#  index_loans_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_5a4bc9458a  (division_id => divisions.id)
#  fk_rails_7a8d917bd9  (secondary_agent_id => people.id)
#  fk_rails_ade0930898  (currency_id => currencies.id)
#  fk_rails_dc1094f4ed  (organization_id => organizations.id)
#  fk_rails_ded298065b  (representative_id => people.id)
#  fk_rails_e90f6505d8  (primary_agent_id => people.id)
#

class Loan < ActiveRecord::Base
  include Translatable
  include MediaAttachable
  include OptionSettable

  QUESTION_SET_TYPES = %i(criteria post_analysis)
  DEFAULT_STEP_NAME = '[default]'
  STATUS_ACTIVE_VALUE = 'active'
  STATUS_COMPLETED_VALUE = 'completed'

  belongs_to :division
  belongs_to :organization
  belongs_to :primary_agent, class_name: 'Person'
  belongs_to :secondary_agent, class_name: 'Person'
  belongs_to :currency
  belongs_to :representative, class_name: 'Person'
  has_many :timeline_entries, as: :project
  has_many :project_logs, through: :timeline_entries, source: :project, source_type: 'ProjectStep'
  has_one :criteria, -> { where("loan_response_sets.kind" => 'criteria') }, class_name: "LoanResponseSet"
  has_one :post_analysis, -> { where("loan_response_sets.kind" => 'post_analysis') }, class_name: "LoanResponseSet"

  scope :country, ->(country) {
    joins(division: :super_division).where('super_divisions_Divisions.Country' => country) unless country == 'all'
  }
  scope :status, ->(status) { where(status: status) }
  scope :visible, -> { where.not(publicity_status: 'hidden') }

  # define accessor-like convenience methods for the fields stored in the Translations table
  attr_translatable :summary, :details

  # Beware, the methods generated by this include will fail
  # without the corresponding OptionSet records existing in the database.
  attr_option_settable :status, :loan_type, :project_type, :public_level

  validates :division_id, :organization_id, presence: true

  def self.status_active_id
    status_option_set.id_for_value(STATUS_ACTIVE_VALUE)
  end

  def self.default_filter
    {status: 'active', country: 'all'}
  end

  def self.filter_by_params(params)
    params.reverse_merge! self.default_filter
    params[:country] = 'Argentina' if params[:division] == :argentina
    scoped = self.all
    scoped = scoped.country(params[:country]) if params[:country]
    scoped = scoped.status(params[:status]) if params[:status]
    scoped
  end

  # The Loan's timeline entries should be accessed via this root node.
  # Timeline steps are organzed as a tree. The tree has a blank root node (ProjectGroup) that is not shown
  # to the user, but makes it easier to do computations over the tree (instead of each top level group
  # being the root of its own separate tree).
  # May return nil if there are no groups or steps in the loan thus far.
  def root_timeline_entry
    @root_timeline_entry ||= timeline_entries.find_or_create_by(parent_id: nil, type: "ProjectGroup")
  end

  # DEPRECATED - This should not be necessary once we transition to tabular format.
  # Do regular ruby select, to avoid issues with AR caching
  # Note, this means the method returns an array, not an AR::Relation
  def project_steps
    timeline_entries.order(:scheduled_start_date).select { |e| e.type == 'ProjectStep' }
  end

  def agent_names
    primary_name = primary_agent ? primary_agent.name : ''
    secondary_name = secondary_agent ? secondary_agent.name : ''
    [primary_name, secondary_name]
  end

  def default_name
    date = signing_date || created_at.to_date
    I18n.t("loan.default_loan_name", org: organization.name, date: I18n.l(date))
  end

  def display_name
    if self.name.blank?
      self.default_name
    else self.name end
  end

  # todo: shall we migrate the display usage to the more verbose version?
  def status
    status_label
  end

  def loan_type
    loan_type_label
  end

  # Gets embedded urls from criteria data. Returns empty array if criteria not defined yet.
  def criteria_embedded_urls
    criteria.try(:embedded_urls) || []
  end

  # creates / reuses a default step when migrating ProjectLogs without a proper owning step
  # beware, not at all optimized, but sufficient for migration.
  # not sure if this will be useful beyond migration.  if so, perhaps worth better optimizing,
  # if not, can remove once we're past the production migration process
  def default_step
    step = project_steps.select{|s| s.summary == DEFAULT_STEP_NAME}.first
    unless step
      # Could perhaps optimize this with a 'find_or_create_by', but would be tricky with the translatable 'summary' field,
      # and it's nice to be able to log the operation.
      logger.info {"default step not found for loan[#{id}] - creating"}

      step = ProjectStep.new(project: self)
      step.update(summary: DEFAULT_STEP_NAME)
    end
    step
  end

  def country
    # TODO: Temporary fix sets country to US when not found
    # @country ||= Country.where(name: self.division.super_division.country).first || Country.where(name: 'United States').first
    #todo: beware code that expected a country to always exist can break if US country not included in seed.data
    @country ||= organization.try(:country) || Country.where(iso_code: 'US').first
  end

  # def currency
  #   # Revisit the default currency  handling later.  Doesn't not seem to be working as desired,
  #   # and this code currently precludes being able to update the currency from the edit form.
  #   @currency ||= self.country.default_currency
  # end

  def location
    if self.organization.try(:city).present?
      self.organization.city + ', ' + self.country.name
    else self.country.name end
  end

  def signing_date_long
    I18n.l self.signing_date, format: :long if self.signing_date
  end

  # def short_description
  #   self.translation('ShortDescription')
  # end
  # def description
  #   self.translation('Description')
  # end

  def coop_media(limit=100, images_only=false)
    get_media('Cooperatives', self.cooperative.try(:id), limit, images_only)
  end

  def loan_media(limit=100, images_only=false)
    get_media('Loans', self.id, limit, images_only)
  end

  def log_media(limit=100, images_only=false)
    media = []
    begin
      self.logs("Date").each do |log|
        media += log.media(limit - media.count, images_only)
        return media unless limit > media.count
      end
    rescue Mysql2::Error # some logs have invalid dates
    end
    return media
  end

  def featured_pictures(limit=1)
    pics = []
    coop_pics = get_media('Cooperatives', self.cooperative.try(:id), limit, images_only=true).to_a
    # use first coop picture first
    pics << coop_pics.shift if coop_pics.count > 0
    return pics unless limit > pics.count
    # then loan pics
    pics += get_media('Loans', self.id, limit - pics.count, images_only=true)
    return pics unless limit > pics.count
    # then log pics
    pics += self.log_media(limit - pics.count, images_only=true)
    return pics unless limit > pics.count
    # then remaining coop pics
    pics += coop_pics[0, limit - pics.count]
    return pics
  end

  def thumb_path
    if !self.featured_pictures.empty?
      self.featured_pictures.first.paths[:thumb]
    else "/assets/ww-avatar-watermark.png" end
  end

  def ensure_currency
    currency || Currency.find_by(code: 'USD')
  end

  def amount_formatted
    ensure_currency.format_amount(amount)
  end

  def project_events(order_by="Completed IS NULL OR Completed = '0000-00-00', Completed, Date")
    @project_events ||= ProjectEvent.includes(project_logs: :progress_metric).
      where("lower(ProjectTable) = 'loans' and ProjectID = ?", self.ID).order(order_by)
    @project_events.reject do |p|
      # Hide past uncompleted project events without logs (for now)
      !p.completed && p.project_logs.empty? && p.date <= Date.today
    end
  end

  def logs
    project_logs
  end

  def calendar_events
    CalendarEvent.build_for(self)
  end
end
