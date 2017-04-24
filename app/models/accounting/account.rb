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

class Accounting::Account < ActiveRecord::Base
  QB_TRANSACTION_TYPE = 'Account'
  belongs_to :project

  has_many :transactions, inverse_of: :account, foreign_key: :accounting_account_id, dependent: :destroy

  def self.find_or_create_from_qb_object(qb_object)
    account = create_with(name: qb_object.name).find_or_create_by qb_id: qb_object.id
    account.tap do |a|
      a.update_attributes!(
        name: qb_object.name,
        qb_account_classification: qb_object.classification,
        quickbooks_data: qb_object.as_json
      )
    end
  end
end
