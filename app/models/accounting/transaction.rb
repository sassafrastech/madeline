# == Schema Information
#
# Table name: accounting_transactions
#
#  accounting_account_id :integer
#  amount                :decimal(, )
#  created_at            :datetime         not null
#  description           :string
#  id                    :integer          not null, primary key
#  loan_transaction_type :string
#  private_note          :string
#  project_id            :integer
#  qb_id                 :string           not null
#  qb_transaction_type   :string           not null
#  quickbooks_data       :json
#  total                 :decimal(, )
#  txn_date              :date
#  updated_at            :datetime         not null
#
# Indexes
#
#  acc_trans_qbid_qbtype_unq_idx                           (qb_id,qb_transaction_type) UNIQUE
#  index_accounting_transactions_on_accounting_account_id  (accounting_account_id)
#  index_accounting_transactions_on_project_id             (project_id)
#  index_accounting_transactions_on_qb_id                  (qb_id)
#  index_accounting_transactions_on_qb_transaction_type    (qb_transaction_type)
#
# Foreign Keys
#
#  fk_rails_3b7e4ae807  (accounting_account_id => accounting_accounts.id)
#  fk_rails_662fd2ba2d  (project_id => projects.id)
#

class Accounting::Transaction < ActiveRecord::Base
  QB_TRANSACTION_TYPES = %w(JournalEntry Deposit Purchase).freeze
  LOAN_TRANSACTION_TYPES = %w(disbursement)

  belongs_to :account, inverse_of: :transactions, foreign_key: :accounting_account_id
  belongs_to :project, inverse_of: :transactions, foreign_key: :project_id

  before_save :update_fields_from_quickbooks_data

  def self.find_or_create_from_qb_object(transaction_type:, qb_object:)
    transaction = find_or_initialize_by qb_transaction_type: transaction_type, qb_id: qb_object.id
    transaction.tap do |t|
      t.update_attributes!(quickbooks_data: qb_object.as_json)
    end
  end

  def quickbooks_data
    read_attribute(:quickbooks_data).with_indifferent_access
  end

  private

  def update_fields_from_quickbooks_data
    return unless quickbooks_data.present?

    self.amount = first_quickbooks_line_item[:amount]
    self.description = first_quickbooks_line_item[:description]
    self.project_id = first_quickbooks_class_name
    self.txn_date = quickbooks_data[:txn_date]
    self.private_note = quickbooks_data[:private_note]
    self.total = quickbooks_data[:total]
  end

  def first_quickbooks_line_item
    return {} unless quickbooks_data[:line_items]
    quickbooks_data[:line_items].first
  end

  def first_quickbooks_class_name
    return unless first_quickbooks_line_item[:journal_entry_line_detail]
    return unless first_quickbooks_line_item[:journal_entry_line_detail][:class_ref]
    first_quickbooks_line_item[:journal_entry_line_detail][:class_ref][:name]
  end
end
