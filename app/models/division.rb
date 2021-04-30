# == Schema Information
#
# Table name: divisions
#
#  accent_fg_color                :string
#  accent_main_color              :string
#  banner_bg_color                :string
#  banner_fg_color                :string
#  closed_books_date              :date
#  created_at                     :datetime         not null
#  currency_id                    :integer
#  custom_data                    :json
#  description                    :text
#  id                             :integer          not null, primary key
#  interest_income_account_id     :integer
#  interest_receivable_account_id :integer
#  internal_name                  :string
#  locales                        :json
#  logo                           :string
#  logo_content_type              :string
#  logo_file_name                 :string
#  logo_file_size                 :integer
#  logo_text                      :string
#  logo_updated_at                :datetime
#  name                           :string
#  notify_on_new_logs             :boolean          default(FALSE)
#  organization_id                :integer
#  parent_id                      :integer
#  principal_account_id           :integer
#  public                         :boolean          default(FALSE), not null
#  qb_parent_class_id             :string
#  qb_read_only                   :boolean          default(TRUE), not null
#  short_name                     :string
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_divisions_on_currency_id                     (currency_id)
#  index_divisions_on_interest_income_account_id      (interest_income_account_id)
#  index_divisions_on_interest_receivable_account_id  (interest_receivable_account_id)
#  index_divisions_on_organization_id                 (organization_id)
#  index_divisions_on_principal_account_id            (principal_account_id)
#  index_divisions_on_short_name                      (short_name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (currency_id => currencies.id)
#  fk_rails_...  (interest_income_account_id => accounting_accounts.id)
#  fk_rails_...  (interest_receivable_account_id => accounting_accounts.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (principal_account_id => accounting_accounts.id)
#

class Division < ApplicationRecord
  include DivisionBased

  has_closure_tree dependent: :restrict_with_exception, order: :name
  resourcify
  alias_attribute :super_division, :parent

  normalize_attributes :logo_text, :banner_fg_color, :banner_bg_color, :accent_main_color, :accent_fg_color

  has_many :loans, dependent: :restrict_with_exception
  has_many :people, dependent: :restrict_with_exception
  has_many :organizations, dependent: :restrict_with_exception

  has_many :questions
  has_many :option_sets, dependent: :destroy

  # Bug in closure_tree requires these 2 lines (https://github.com/mceachen/closure_tree/issues/137)
  has_many :self_and_descendants, through: :descendant_hierarchies, source: :descendant
  has_many :self_and_ancestors, through: :ancestor_hierarchies, source: :ancestor

  has_one :qb_connection, class_name: 'Accounting::QB::Connection', dependent: :destroy, inverse_of: :division
  has_one :qb_department, class_name: 'Accounting::QB::Department', dependent: :nullify, inverse_of: :division
  accepts_nested_attributes_for :qb_department

  belongs_to :principal_account, class_name: "Accounting::Account"
  belongs_to :interest_receivable_account, class_name: "Accounting::Account"
  belongs_to :interest_income_account, class_name: "Accounting::Account"

  belongs_to :parent, class_name: 'Division'

  # Note the requirements around a single currency or a 'default currency' per division has been in
  # flux. Should probably rename the DB column to 'default_currency_id' once definitively settled.
  belongs_to :default_currency, class_name: 'Currency', foreign_key: 'currency_id'
  alias_attribute :default_currency_id, :currency_id

  belongs_to :organization  # the organization which represents this loan agent division

  mount_uploader :logo, LogoUploader

  validate :parent_division_and_name
  validates :name, presence: true
  validates :parent, presence: true, if: -> { Division.root.present? && Division.root_id != id }
  validates :short_name, presence: true, uniqueness: true, if: -> { self.public }

  before_validation :generate_short_name

  scope :by_name, -> { Arel.sql(order("LOWER(divisions.name)")) }
  scope :published, -> { where(public: true) }

  delegate :connected?, to: :qb_connection, prefix: :quickbooks, allow_nil: true
  delegate :company_name, to: :qb_connection, prefix: :quickbooks, allow_nil: true

  attr_accessor :qb_department_id # allows this field in simple_form

  def self.root_id
    result = root.try(:id)
    result
  end

  def self.in_division(division)
    division ? division.self_and_descendants : all
  end

  def self.qb_divisions
    Accounting::QB::Connection.all.map(&:division)
  end

  def self.qb_accessible_divisions
    qb_divisions.map(&:self_and_descendants).flatten.uniq
  end

  # interface compatibility with other models
  def division
    self
  end

  def has_logo_text?
    logo_text.present?
  end

  def has_noncascading_dependents?
    Division.where(parent: self).present? ||
      Organization.where(division: self).present? ||
      Loan.where(division: self).present?  ||
      Person.where(division: self).present?
  end

  def users
    people.with_system_access
  end

  def locales
    return [] unless self[:locales].present?
    self[:locales].sort.select(&:present?).map(&:to_sym)
  end

  def locale_names
    locales.map do |locale|
      I18n.t("locale_name.#{locale}", locale: locale)
    end
  end

  def accounts
    @accounts ||= [principal_account, interest_receivable_account, interest_income_account].compact
  end

  def qb_accounts_selected?
    accounts.size == 3
  end

  # If no QB connection on this division, fall back to nearest ancestor with QB connection.
  # May return nil.
  def qb_division
    # Division.root
    qb_connection ? self : parent&.qb_division
  end

  def qb_department?
    qb_department.present?
  end

  def parent_division_and_name
    errors.add(:parent, :invalid) if parent&.name == name
  end

  def generate_short_name
    # no change to short_name that is already saved and therefore uniq
    return if self.short_name.present? && self.short_name == self.attribute_in_database(:short_name)

    # manual change to new uniq short name
    return if self.short_name.present? && Division.pluck(:short_name).exclude?(self.short_name)

    # shortname not provided or provided shortname is not uniq
    self.short_name ||= name.parameterize
    self.short_name = "#{self.short_name}-#{SecureRandom.uuid}" if Division.pluck(:short_name).include?(self.short_name)
  end
end
