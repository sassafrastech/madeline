# == Schema Information
#
# Table name: accounting_accounts
#
#  created_at                :datetime         not null
#  id                        :integer          not null, primary key
#  name                      :string           not null
#  qb_account_classification :string
#  qb_id                     :string           not null
#  quickbooks_data           :json
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_accounting_accounts_on_qb_id  (qb_id)
#

# Represents an account as in a typical double-entry accounting system.
# Accounts defined in the associated Quickbooks instance are synced and cached locally on Madeline.
# Quickbooks should be considered the authoritative source for account information.
class Accounting::Account < ActiveRecord::Base
  QB_TRANSACTION_TYPE = 'Account'
  belongs_to :project

  has_many :transactions, inverse_of: :account, foreign_key: :accounting_account_id, dependent: :destroy
  has_many :line_items, inverse_of: :account, foreign_key: :accounting_account_id, dependent: :destroy

  def self.create_or_update_from_qb_object(transaction_type:, qb_object:)
    account = find_or_initialize_by qb_id: qb_object.id
    account.tap do |a|
      a.update_attributes!(
        name: qb_object.name,
        qb_account_classification: qb_object.classification,
        quickbooks_data: qb_object.as_json
      )
    end
  end

  def self.asset_accounts
    where(qb_account_classification: 'Asset')
  end
end
