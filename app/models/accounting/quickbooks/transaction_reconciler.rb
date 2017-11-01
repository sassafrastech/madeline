module Accounting
  module Quickbooks
    # Responsible for updating or creating transaction entries in quickbooks.
    class TransactionReconciler
      def initialize(qb_division = Division.root)
        @qb_division = qb_division
        @qb_connection = qb_division.qb_connection
        @principal_account = qb_division.principal_account
      end

      # Creates a transaction in Quickbooks based on a Transaction object created in Madeline. Line
      # items in QB mirror line items in Madeline.
      def reconcile(transaction)
        return unless transaction.present?

        je = builder.build_for_qb(transaction)

        if transaction.qb_id.present?
          journal_entry = service.update(je)
        else
          journal_entry = service.create(je)
        end

        journal_entry
      end

      private

      attr_reader :qb_connection, :principal_account, :qb_division

      def builder
        @builder ||= TransactionBuilder.new(qb_division)
      end

      def service
        @service ||= ::Quickbooks::Service::JournalEntry.new(qb_connection.auth_details)
      end
    end
  end
end
