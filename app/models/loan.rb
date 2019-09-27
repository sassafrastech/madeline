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

class Loan < Project
  include MediaAttachable

  QUESTION_SET_TYPES = %i(criteria post_analysis)
  DEFAULT_STEP_NAME = '[default]'
  STATUS_ACTIVE_VALUE = 'active'
  STATUS_COMPLETED_VALUE = 'completed'

  belongs_to :organization
  belongs_to :currency
  belongs_to :representative, class_name: 'Person'
  has_one :criteria, -> { where("response_sets.kind" => 'criteria') }, class_name: "ResponseSet"
  has_one :post_analysis, -> { where("response_sets.kind" => 'post_analysis') }, class_name: "ResponseSet"
  has_one :health_check, class_name: "LoanHealthCheck", foreign_key: :loan_id, dependent: :destroy

  scope :status, ->(status) { where(status_value: status) }
  scope :active, -> { status("active") }
  scope :completed, -> { status("completed") }
  scope :active_or_completed, -> { where(status_value: %w(active completed)) }
  scope :related_loans, ->(loan) { loan.organization.loans.where.not(id: loan.id) }

  delegate :name, :country, :postal_code, to: :organization, prefix: :coop
  # adding these because if someone clicks 'All' on the loans public page
  # the url divisions are set as strings not symbols
  # These are the ones we're certain of at the moment
  URL_DIVISIONS = %w(us argentina nicaragua)

  # Beware, the methods generated by this include will fail
  # without the corresponding OptionSet records existing in the database.
  attr_option_settable :status, :loan_type, :public_level

  validates :organization, :public_level_value, presence: true

  before_create :build_health_check
  after_commit :recalculate_loan_health

  def self.default_filter
    {status: 'active', country: 'all'}
  end

  def self.filter_by_params(params)
    params.reverse_merge! self.default_filter
    scoped = self.all
    scoped = scoped.status(params[:status]) if params[:status] != 'all'

    if params[:division] != 'all'
      division_ids = Division.find_by(short_name: params[:division])&.self_and_descendants&.select(&:public?)&.map(&:id)
    else
      division_ids = Division.root.descendants.select(&:public?)&.map(&:id)
    end

    scoped = scoped.where(division: division_ids)

    scoped
  end

  # Rate is entered as a percent
  def interest_rate
    rate / 100 if rate
  end

  def recalculate_loan_health
    RecalculateLoanHealthJob.perform_later(loan_id: id)
  end

  def default_name
    return unless organization.present?
    date = signing_date || created_at.to_date

    # date will always return a value so there is no need to use ldate
    "#{organization.name} - #{I18n.l(date)}"
  end

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

  def country
    # TODO: Temporary fix sets country to US when not found
    # @country ||= Country.where(name: self.division.super_division.country).first || Country.where(name: 'United States').first
    #todo: beware code that expected a country to always exist can break if US country not included in seed.data
    @country ||= organization.try(:country) || Country.where(iso_code: 'US').first
  end

  def display_currency
    currency ? currency.try(:name) : ''
  end

  def location
    if self.organization.try(:city).present?
      self.organization.city + ', ' + self.country.name
    else self.country.name end
  end

  def signing_date_long
    # this may or may not be available so setting a default value
    I18n.l(self.signing_date, format: :long, default: '')
  end

  def coop_media(limit: 100, images_only: false)
    organization.get_media(limit: limit, images_only: images_only)
  end

  def loan_media(limit: 100, images_only: false)
    self.get_media(limit: limit, images_only: images_only)
  end

  def log_media(limit: 100, images_only: false)
    media = []
    self.project_logs.find_each do |log|
      media += log.get_media(limit: limit - media.count, images_only: images_only)
      return media unless limit > media.count
    end
    media
  end

  def featured_pictures(limit: 1)
    pics = []
    coop_pics = coop_media(limit: limit, images_only: true).to_a
    # use first coop picture first
    pics << coop_pics.shift if coop_pics.count > 0
    return pics unless limit > pics.count
    # then loan pics
    pics += loan_media(limit: limit - pics.count, images_only: true)
    return pics unless limit > pics.count
    # then log pics
    pics += log_media(limit: limit - pics.count, images_only: true)
    return pics unless limit > pics.count
    # then remaining coop pics
    pics += coop_pics[0, limit - pics.count]
    return pics
  end

  def thumb_path
    if !self.featured_pictures.empty?
      self.featured_pictures.first.item.thumb.url
    else "/images/ww-avatar-watermark.png" end
  end

  def ensure_currency
    currency || Currency.find_by(code: 'USD')
  end

  def active?
    status_value == 'active'
  end

  def healthy?
    return false unless health_check
    health_check.healthy?
  end

  def health_status_available?
    return !health_check.nil?
  end

  def sum_of_disbursements(start_date: nil, end_date: nil)
    return nil if transactions.empty?
    transactions.by_type("disbursement").in_date_range(start_date, end_date).map { |t| t.amount }.sum
  end

  def sum_of_repayments(start_date: nil, end_date: nil)
    return nil if transactions.empty?
    transactions.by_type("repayment").in_date_range(start_date, end_date).map { |t| t.amount }.sum
  end

  def change_in_interest(start_date: nil, end_date: nil)
    return nil if transactions.empty?
    transactions.in_date_range(start_date, end_date).map { |t| t.change_in_interest }.sum
  end

  def change_in_principal(start_date: nil, end_date: nil)
    return nil if transactions.empty?
    transactions.in_date_range(start_date, end_date).map { |t| t.change_in_principal }.sum
  end
end
