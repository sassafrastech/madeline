# == Schema Information
#
# Table name: organizations
#
#  alias              :string
#  city               :string
#  contact_notes      :text
#  country_id         :integer
#  created_at         :datetime         not null
#  custom_data        :json
#  division_id        :integer
#  email              :string
#  fax                :string
#  id                 :integer          not null, primary key
#  industry           :string
#  is_recovered       :boolean
#  last_name          :string
#  legal_name         :string
#  name               :string
#  neighborhood       :string
#  postal_code        :string
#  primary_contact_id :integer
#  primary_phone      :string
#  referral_source    :string
#  secondary_phone    :string
#  sector             :string
#  state              :string
#  street_address     :text
#  tax_no             :string
#  updated_at         :datetime         not null
#  website            :string
#
# Indexes
#
#  index_organizations_on_division_id  (division_id)
#
# Foreign Keys
#
#  fk_rails_0de9c8b6c9  (country_id => countries.id)
#  fk_rails_a43f2db6ae  (primary_contact_id => people.id)
#  fk_rails_e5fef62474  (division_id => divisions.id)
#

class Organization < ActiveRecord::Base
  include Contactable  # this is a placeholder concern for the shared aspects between Organization and People.
  include Notable
  include MediaAttachable

  belongs_to :division
  belongs_to :country
  belongs_to :primary_contact, class_name: 'Person'

  has_many :loans, dependent: :destroy
  has_many :people, foreign_key: :primary_organization_id, dependent: :nullify

  validates :name, presence: true
  validates :division_id, presence: true

  def loans_count
    loans.size
  end

  def active_loans
    loans.where(status_value: Loan::STATUS_ACTIVE_VALUE)
  end

end
