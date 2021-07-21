# Updater is responsible for grabbing only the updates that have happened in Quickbooks
# since the last time this class was run. If no Quickbooks data exists in the system
# yet, FullFetcher will need to be run first.
# Updater also kicks off the recalculation process in InterestCalculator once it is done fetching.
module Accounting
  module QB
    class Updater
      attr_reader :qb_connection

      MIN_TIME_BETWEEN_UPDATES = 5.seconds

      def initialize(qb_connection = Division.root.qb_connection)
        @qb_connection = qb_connection
        @connected = @qb_connection&.connected?
      end

      # If the loan parameter is given, this method extracts QB data for Transactions
      # related to ONLY the given loan. See extract_qb_data for more details.
      #
      # This argument can either be a single loan or an array of loans
      def update(loans = nil)
        # Delete only global issues now before fetch phase but keep loan-specific
        # issues so that if fetch fails we still hide those loans' txn data appropriately.
        Accounting::SyncIssue.global.delete_all
        started_update_at = Time.zone.current
        qb_sync_for_loan_update
        if loans
          # check if loan is one object or multiple
          loans = [loans] if loans.is_a? Loan
          loans.each do |loan|
            update_loan(loan)
          end
        end
        # TODO: This is duplicated in QuickbooksUpdateJob and needs to be DRYed up.
        # We record last_updated_at as the time this update started. The user-prompted ways
        # the update is started are used by only admins and rarely.
        Rails.logger.debug("Setting qb cnxn last_updated_at to #{started_update_at}"
        qb_connection.update_attribute(:last_updated_at, started_update_at)
      end

      # Fetches all changes from Quickbooks since the last update.
      # Note that *all* changes are pulled from Quickbooks even if the `loan` parameter is given.
      # Fetched data is initially stored in the objects' qb_data attribute, but NOT copied into the
      # associated attributes.
      #
      # `changes` method raises a DataResetRequiredError if there are updates
      # too far in the past for the `since` method to access.
      #
      def qb_sync_for_loan_update
        raise NotConnectedError unless @connected
        raise AccountsNotSelectedError unless Division.root.qb_accounts_selected?
        return if too_soon_to_run_again?

        changes.each do |type, qb_objects|
          qb_objects.each do |qb_object|
            if should_be_deleted?(qb_object)
              delete_qb_object(qb_object_type: type, qb_object: qb_object)
            else
              create_or_update(qb_object_type: type, qb_object: qb_object)
            end
          end
        end
      end

      # To update a loan, we first must extract any new qb data on its txns.
      # Then we run the interest calculator, which depends on extracted qb data.
      # Though interest calculation calculates balances on any loans whose interest
      # is calculated, we call calculate balances again after the interest calculation
      # because not all loans have their interest calculated in 'recalculate', but all loans need
      # their balances calculated. Note: attempting to calculate balances
      # on all loans before interest calculation has caused problems in the past.
      def update_loan(loan)
        # Delete loan-specific issues now that we are ready to recompute.
        Accounting::SyncIssue.for_loan(loan).delete_all
        extract_qb_data(loan)
        InterestCalculator.new(loan).recalculate
        calculate_balances(loan)
      end

      private

      # Extracts data for txns from the JSON in `quickbooks_data`
      # into each Transaction's attributes and associated LineItems.
      # Creates/deletes LineItems as needed.
      def extract_qb_data(loan)
        if loan.transactions.present?
          loan.transactions.standard_order.each do |txn|
            if txn.quickbooks_data.present?
              log_data = {loan_id: loan.id, txn_id: txn.id, txn_qb_id: txn.qb_id}
              Rails.logger.debug("Extracting transaction #{log_data}")
              Accounting::QB::DataExtractor.new(txn).extract!
              txn.save!
            end
          end
        end
      end

      def calculate_balances(loan)
        if loan.transactions.present?
          prev_tx = nil
          loan.transactions.standard_order.each do |txn|
            txn.calculate_balances(prev_tx: prev_tx)
            txn.save!
            prev_tx = txn
          end
        end
      end

      def too_soon_to_run_again?
        return false if qb_connection.last_updated_at.nil?
        Time.current - qb_connection.last_updated_at < MIN_TIME_BETWEEN_UPDATES
      end

      def changes
        # assumes that after a new qb connection has been established, the FullFetcher will
        # retrieve all data from qb and last_updated_at will have a value before updater runs.
        unless last_updated_at && last_updated_at > max_updated_at
          raise DataResetRequiredError
        end
        Rails.logger.debug("Calling to QB API to get changes since #{last_updated_at}")
        service.since(types, last_updated_at).all_types
      end

      def create_or_update(qb_object_type:, qb_object:)
        model = ar_model_for(qb_object_type)
        model.create_or_update_from_qb_object!(qb_object_type: qb_object_type, qb_object: qb_object)
      end

      def types
        Transaction::QB_OBJECT_TYPES +
          [Account::QB_OBJECT_TYPE] +
          [Customer::QB_OBJECT_TYPE] +
          [Vendor::QB_OBJECT_TYPE] +
          [Department::QB_OBJECT_TYPE]
      end

      def ar_model_for(qb_object_type)
        return Account if Account::QB_OBJECT_TYPE == qb_object_type
        return Customer if Customer::QB_OBJECT_TYPE == qb_object_type
        return Vendor if Vendor::QB_OBJECT_TYPE == qb_object_type
        return Department if Department::QB_OBJECT_TYPE == qb_object_type
        Transaction
      end

      def delete_qb_object(qb_object_type:, qb_object:)
        model = ar_model_for(qb_object_type)
        model.where(qb_id: qb_object.id).destroy_all
      end

      def should_be_deleted?(qb_object)
        qb_object.try(:status) == 'Deleted'
      end

      def service
        ::Quickbooks::Service::ChangeDataCapture.new(qb_connection.auth_details)
      end

      def max_updated_at
        # based on oldest data since method will retrieve (https://github.com/ruckus/quickbooks-ruby)
        30.days.ago
      end

      def last_updated_at
        qb_connection.last_updated_at
      end
    end
  end
end
