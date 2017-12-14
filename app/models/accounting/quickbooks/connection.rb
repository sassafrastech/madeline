# == Schema Information
#
# Table name: accounting_quickbooks_connections
#
#  created_at       :datetime         not null
#  division_id      :integer
#  id               :integer          not null, primary key
#  last_updated_at  :datetime
#  realm_id         :string
#  secret           :string
#  token            :string
#  token_expires_at :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_accounting_quickbooks_connections_on_division_id  (division_id)
#
# Foreign Keys
#
#  fk_rails_...  (division_id => divisions.id)
#

class Accounting::Quickbooks::Connection < ActiveRecord::Base
  belongs_to :division

  def self.create_from_access_token(access_token:, division:, params:)
    create(
      token: access_token.token,
      secret: access_token.secret,
      division: division,
      realm_id: params['realmId'],
      token_expires_at: 180.days.from_now
    )
  end

  def connected?
    !expired? && token.present? && secret.present? && realm_id.present?
  end

  def expired?
    return token_expires_at < Time.zone.now if token_expires_at
    false
  end

  def renewable?
    return token_expires_at < 30.days.from_now if token_expires_at && connected?
    false
  end

  def auth_details
    { access_token: access_token, company_id: realm_id }
  end

  def access_token
    Accounting::Quickbooks::Consumer.new.access_token(token: token, secret: secret)
  end
end
