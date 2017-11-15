# Does a full sync with Quickbooks for Accounts and Transactions. Creates new objects as needed, and
# updates existing objects.
module Accounting
  module Quickbooks
    class FullFetcher
      attr_reader :qb_connection

      def initialize(qb_connection = Division.root.qb_connection)
        @qb_connection = qb_connection
      end

      def fetch_all
        started_fetch_at = Time.zone.now

        ::Accounting::Quickbooks::AccountFetcher.new.fetch
        ::Accounting::Quickbooks::TransactionFetcher.new.fetch

        qb_connection.update_attribute(:last_updated_at, started_fetch_at)
      end
    end
  end
end
