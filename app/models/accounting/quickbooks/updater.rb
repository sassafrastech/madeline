module Accounting
  module Quickbooks

    # Reponsible for grabbing only the updates that have happened in quickbooks
    # since the last time this class was run. If no quickbooks data exists in the sytem
    # yet, FullFetcher will need to be run first.
    class Updater
      attr_reader :qb_connection

      MIN_TIME_BETWEEN_UPDATES = 5.seconds

      def initialize(qb_connection = Division.root.qb_connection)
        @qb_connection = qb_connection
      end

      # checks that accounts and transactions are found, created, updated or deleted
      def update(loan = nil)
        raise NotConnectedError unless qb_connection
        return if too_soon_to_run_again?

        updated_models = changes.flat_map do |type, qb_objects|
          qb_objects.map do |qb_object|
            if should_be_deleted?(qb_object)
              delete_qb_object(transaction_type: type, qb_object: qb_object)
            else
              find_or_create(transaction_type: type, qb_object: qb_object)
            end
          end
        end

        # We record last_updated_at as the time the update *finishes* because last_updated_at
        # is used to avoid runs that immediately follow each other as in the case of a transaction creation
        # followed by a transaction listing. If we record the time the update *started* and the update
        # takes some time, we would need to increase the MIN_TIME_BETWEEN_UPDATES value and that might
        # make it frustrating for users who want to deliberately re-run the updater.
        # The other function of last_updated_at is to check if a full sync needs to be run,
        # but that condition is measured in days, not seconds, so this small a difference shouldn't matter.
        qb_connection.update_attribute(:last_updated_at, Time.now)

        update_ledger(loan) if loan

        updated_models
      end

      private

      def too_soon_to_run_again?
        return false if qb_connection.last_updated_at.nil?
        Time.now - qb_connection.last_updated_at < MIN_TIME_BETWEEN_UPDATES
      end

      def update_ledger(loan)
        loan.transactions.standard_order.each do |txn|
          extract_qb_data(txn)
          txn.reload.calculate_balances
        end
      end

      def extract_qb_data(txn)
        return unless txn.quickbooks_data.present?

        # removed line_item doesn't make it into the second loop so it is still available in Madeline
        # so we delete them
        if txn.quickbooks_data['line_items'].count < txn.line_items.count
          qb_ids = txn.quickbooks_data['line_items'].map{ |h| h['id'].to_i }

          txn.line_items.each do |li|
            li.destroy unless qb_ids.include?(li.qb_line_id)
          end
        end

        txn.quickbooks_data['line_items'].each do |li|
          acct_name = li['journal_entry_line_detail']['account_ref']['name']
          acct = Accounting::Account.find_by(name: acct_name)

          # skip if line item does not have an account in Madeline
          next unless acct

          Accounting::LineItem.find_or_initialize_by(qb_line_id: li['id'], parent_transaction: txn).
            update!(account: acct, amount: li['amount'], posting_type: li['journal_entry_line_detail']['posting_type'])
        end

        txn.txn_date = txn.quickbooks_data['txn_date']
        txn.private_note = txn.quickbooks_data['private_note']
        txn.total = txn.quickbooks_data['total']
        txn.amount = (txn.change_in_interest + txn.change_in_principal).abs
        txn.save!
      end

      def changes
        raise FullSyncRequiredError, "Last update was more than 30 days ago, please do a full sync" unless last_updated_at && last_updated_at > max_updated_at

        service.since(types, last_updated_at).all_types
      end

      def find_or_create(transaction_type:, qb_object:)
        model = ar_model_for(transaction_type)
        model.create_or_update_from_qb_object transaction_type: transaction_type, qb_object: qb_object
      end

      def types
        Accounting::Transaction::QB_TRANSACTION_TYPES + [Accounting::Account::QB_TRANSACTION_TYPE]
      end

      def ar_model_for(transaction_type)
        return Accounting::Account if Accounting::Account::QB_TRANSACTION_TYPE == transaction_type
        Accounting::Transaction
      end

      def delete_qb_object(transaction_type:, qb_object:)
        model = ar_model_for(transaction_type)
        model.where(qb_id: qb_object.id).destroy_all
      end

      def should_be_deleted?(qb_object)
        qb_object.try(:status) == 'Deleted'
      end

      def service
        ::Quickbooks::Service::ChangeDataCapture.new(qb_connection.auth_details)
      end

      def max_updated_at
        30.days.ago - 1.minute
      end

      def last_updated_at
        qb_connection.last_updated_at
      end
    end
  end
end
