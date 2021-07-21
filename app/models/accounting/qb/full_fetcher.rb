# Does a full reset with Quickbooks for Accounts and Transactions. Creates new objects as needed, and
# updates existing objects.
module Accounting
  module QB
    class FullFetcher
      attr_reader :qb_connection, :division

      def initialize(division)
        @division = division
        @qb_connection = division.qb_connection
      end

      def fetch_all
        accounts = clear_accounts!
        department_division_map = clear_department_associations!
        delete_qb_data
        fetch_qb_data
        restore_accounts!(accounts)
        restore_department_associations!(department_division_map)
        Task.create(
          job_class: UpdateAllLoansJob,
          job_type_value: 'update_all_loans',
          activity_message_value: 'task_enqueued'
        ).enqueue
      rescue StandardError => error
        @qb_connection&.destroy
        raise error
      end

      private

      def fetch_qb_data
        started_fetch_at = Time.zone.current
        ::Accounting::QB::TransactionClassFinder.new(division).find_by_name(::Accounting::Transaction::QB_PARENT_CLASS)
        ::Accounting::QB::CustomerFetcher.new(division).fetch
        ::Accounting::QB::AccountFetcher.new(division).fetch
        ::Accounting::QB::TransactionFetcher.new(division).fetch
        ::Accounting::QB::DepartmentFetcher.new(division).fetch
        ::Accounting::QB::VendorFetcher.new(division).fetch
        qb_connection.update_attribute(:last_updated_at, started_fetch_at)
      rescue StandardError => error
        delete_qb_data
        clear_division_accounts
        raise error # to be caught in fetch_all
      end

      def delete_qb_data
        ::Accounting::LineItem.delete_all
        ::Accounting::SyncIssue.delete_all
        ::Accounting::Transaction.delete_all
        ::Accounting::Account.delete_all
        ::Accounting::Customer.delete_all
        ::Accounting::QB::Department.delete_all
        ::Accounting::QB::Vendor.delete_all
      end

      # Set this division's accounts to nil and return a hash of the QB ids of the removed accounts
      def clear_accounts!
        accounts_qb_ids = {
          principal: division.principal_account&.qb_id,
          interest_receivable: division.interest_receivable_account&.qb_id,
          interest_income: division.interest_income_account&.qb_id,
        }
        clear_division_accounts
        accounts_qb_ids
      end

      def clear_division_accounts
        division.update(
          principal_account_id: nil,
          interest_receivable_account_id: nil,
          interest_income_account_id: nil,
        )
      end

      def clear_department_associations!
        department_division_map = {}
        Accounting::QB::Department.find_each do |d|
          department_division_map[d.qb_id] = d.division_id
        end
        department_division_map
      end

      # Restore all divisions' accounts to the ones passed in. Argument is expected to be a hash of
      # the form returned by `#clear_accounts!`. NOTE: If a previously selected account no longer
      # exists after the full sync from QB, it will be set to nil. This is by design.
      def restore_accounts!(accounts_qb_ids)
        division.update(
          principal_account:
            Accounting::Account.find_by(qb_id: accounts_qb_ids[:principal]),
          interest_receivable_account:
            Accounting::Account.find_by(qb_id: accounts_qb_ids[:interest_receivable]),
          interest_income_account:
            Accounting::Account.find_by(qb_id: accounts_qb_ids[:interest_income]),
        )
      end

      def restore_department_associations!(department_division_map)
        Accounting::QB::Department.find_each do |d|
          d.update_attribute(:division_id, department_division_map[d.qb_id])
        end
      end
    end
  end
end
