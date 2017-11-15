# TransactionBuilder is responsible for building Quickbooks JournalEntry objects from Madeline Transactions.
# Note that these JournalEntrys may or may not already exist in Quickbooks. This is because we
# need a fully initialized JournalEntry object to perform both creates AND updates via the Quickbooks API.
# This class is NOT responsible for running the actual create/update operation via the API.
#
# However, it may initiate API calls while getting references for customer (QB equivalent for Organization),
# department (QB equivalent for Division), and class (QB equivalent for Loan) if corresponding
# objects don't exist yet in Quickbooks.
module Accounting
  module Quickbooks
    class TransactionBuilder
      attr_reader :qb_connection, :principal_account

      def initialize(qb_division = Division.root)
        @qb_connection = qb_division.qb_connection
        @principal_account = qb_division.principal_account
      end

      # Creates a transaction for Quickbooks based on a Transaction object created in Madeline. Line
      # items in QB mirror line items in Madeline.
      def build_for_qb(transaction)
        je = ::Quickbooks::Model::JournalEntry.new
        je.private_note = transaction.private_note
        je.txn_date = transaction.txn_date if transaction.txn_date.present?

        qb_customer_ref = customer_reference(transaction.project.organization)
        qb_department_ref = department_reference(transaction.project)

        # We use the journal entry class field to store the loan ID.
        # The loan ID is actually stored as the 'name' of the class object in Quickbooks.
        # Note that 'class' in Quickbooks has nothing to do with a class in Ruby. It's just a
        # bit of metadata about the journal entry.
        # The QBO api needs a fully persisted class before we can associate it.
        # We need to either find or create the class, and use the returned Id.
        qb_class_id = find_or_create_qb_class(loan_id: transaction.project_id).id

        transaction.line_items.each do |li|
          je.line_items << build_line_item(
            amount: li.amount,
            posting_type: li.posting_type,
            description: li.description,
            qb_account_id: li.account.qb_id,
            qb_customer_ref: qb_customer_ref,
            qb_department_ref: qb_department_ref,
            qb_class_id: qb_class_id
          )
        end

        je
      end

      private

      def customer_reference(organization)
        Customer.new(organization: organization, qb_connection: qb_connection).reference
      end

      def department_reference(loan)
        Department.new(division: loan.division, qb_connection: qb_connection).reference
      end

      def service
        @service ||= ::Quickbooks::Service::JournalEntry.new(qb_connection.auth_details)
      end

      def class_service
        @class_service ||= ::Quickbooks::Service::Class.new(qb_connection.auth_details)
      end

      # Builds a Quickbooks `Line` object, which represents a Quickbooks line item, not to be confused
      # with a Madeline LineItem.
      def build_line_item(amount:, posting_type:, description:, qb_account_id:,
        qb_customer_ref:, qb_department_ref:, qb_class_id:)
        line_item = ::Quickbooks::Model::Line.new
        line_item.detail_type = 'JournalEntryLineDetail'
        jel = ::Quickbooks::Model::JournalEntryLineDetail.new
        line_item.journal_entry_line_detail = jel

        jel.entity = qb_customer_ref
        jel.department_ref = qb_department_ref
        jel.class_id = qb_class_id

        line_item.amount = amount
        line_item.description = description
        jel.posting_type = posting_type
        jel.account_id = qb_account_id

        line_item
      end

      # We use the Quickbooks 'classes' to store the loan IDs.
      # This method finds or creates a QB class to hold a given loan ID.
      def find_or_create_qb_class(loan_id:)
        loan_ref = class_service.find_by(:name, loan_id).first
        return loan_ref if loan_ref

        qb_class = ::Quickbooks::Model::Class.new
        qb_class.name = loan_id

        class_service.create(qb_class)
      end
    end
  end
end
