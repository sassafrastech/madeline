require 'rails_helper'

RSpec.describe Accounting::Quickbooks::TransactionBuilder, type: :model do
  let(:class_ref) { instance_double(Quickbooks::Model::Class, id: loan_id) }
  let(:class_service) { instance_double(Quickbooks::Service::Class, find_by: [class_ref]) }
  let(:customer_service) { instance_double(Quickbooks::Service::Customer) }
  let(:department_service) { instance_double(Quickbooks::Service::Department) }
  let(:connection) { instance_double(Accounting::Quickbooks::Connection) }
  let(:principal_account) { create(:accounting_account, qb_id: qb_principal_account_id) }
  let(:bank_account) { create(:accounting_account, qb_id: qb_bank_account_id) }
  let(:office_account) { create(:accounting_account, qb_id: qb_office_account_id) }
  let(:loan) { create(:loan) }
  let(:loan_id) { loan.id }
  let(:amount) { 78.20 }
  let(:memo) { 'I am a memo' }
  let(:description) { 'I am a line item description' }
  let(:qb_bank_account_id) { '89' }
  let(:qb_principal_account_id) { '92' }
  let(:qb_office_account_id) { '1' }
  let(:date) { nil }
  let(:transaction) do
    Accounting::Transaction.new(
      amount: amount,
      project: loan,
      private_note: memo,
      description: description,
      account: bank_account,
      loan_transaction_type_value: 'Disbursement',
      txn_date: date
    )
  end

  let(:line_item_1) {
    build(:line_item,
      account: principal_account,
      posting_type: 'Debit',
      amount: 100
    )
  }

  let(:line_item_2) {
    build(:line_item,
      account: bank_account,
      posting_type: 'Credit',
      amount: 25
    )
  }

  let(:line_item_3) {
    build(:line_item,
      account: office_account,
      posting_type: 'Credit',
      amount: 75
    )
  }

  subject do
    described_class.new(instance_double(Division, qb_connection: connection, principal_account: principal_account))
  end

  before do
    allow(subject).to receive(:class_service).and_return(class_service)
    allow(subject).to receive(:customer_reference).and_return(customer_reference)
    allow(subject).to receive(:department_reference).and_return(department_reference)

    # since transaction does not exist yet
    transaction.line_items << [line_item_1, line_item_2, line_item_3]
  end

  let(:qb_customer_id) { '91234' }
  let(:qb_department_id) { '4012' }
  let(:customer_reference) { instance_double(Quickbooks::Model::Entity) }
  let(:department_reference) { instance_double(Quickbooks::Model::BaseReference, value: qb_department_id) }
  let(:customer_name) { 'A cooperative with a name' }
  let(:organization) { create(:organization, name: customer_name, qb_id: nil) }

  it 'calls create with correct data' do
    je = subject.build_for_qb transaction

    expect(je.line_items.count).to eq 3
    expect(je.private_note).to eq memo
    expect(je.doc_number).to eq 'MS-Managed'
    expect(je.txn_date).to be_nil

    list = je.line_items
    expect(list.map(&:amount)).to eq transaction.line_items.map(&:amount)
    expect(list.map(&:description).uniq).to eq ['I am a line item description']

    details = list.map { |i| i.journal_entry_line_detail }
    expect(details.map { |i| i.posting_type }.uniq).to match_array %w(Debit Credit)
    expect(details.map { |i| i.entity }.uniq).to eq [customer_reference]
    expect(details.map { |i| i.class_ref.value }.uniq).to eq [loan_id]
    # parent_ref on a qb class is not queryable in qb api, so not tested here; must use qb
    # to verify that parent class set correctly
    expect(details.map { |i| i.department_ref.value }.uniq).to eq [qb_department_id]
    expect(details.map { |i| i.account_ref.value }.uniq).to match_array [qb_bank_account_id, qb_principal_account_id, qb_office_account_id]
  end

  context 'and date is supplied' do
    let(:date) { 3.days.ago.to_date }

    it 'creates JournalEntry with date' do
      je = subject.build_for_qb transaction
      expect(je.txn_date).to eq date
    end
  end

  it 'creates JournalEntry with a reference to the existing loan' do
    expect(class_service).to receive(:find_by).with(:name, "Loan ID #{loan_id}")
    subject.build_for_qb transaction
  end
end
