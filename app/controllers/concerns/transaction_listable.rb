module TransactionListable
  extend ActiveSupport::Concern

  def initialize_transactions_grid(project_id = nil)
    begin
      ::Accounting::Quickbooks::AccountFetcher.new.fetch
      ::Accounting::Quickbooks::TransactionFetcher.new.fetch
    rescue Quickbooks::ServiceUnavailable => e
      Rails.logger.error e
      flash.now[:error] = t('quickbooks.service_unavailable')
    rescue Quickbooks::MissingRealmError,
      Quickbooks::AuthorizationFailure => e
      Rails.logger.error e
      flash.now[:error] = t('quickbooks.authorization_failure', settings: view_context.link_to(t('menu.settings'), admin_settings_path)).html_safe
    rescue Quickbooks::InvalidModelException,
      Quickbooks::Forbidden,
      Quickbooks::ThrottleExceeded,
      Quickbooks::TooManyRequests,
      Quickbooks::IntuitRequestException => e
      Rails.logger.error e
      ExceptionNotifier.notify_exception(e)
      flash.now[:error] = t('quickbooks.misc')
    end

    if project_id
      @transactions = ::Accounting::Transaction.where(project_id: project_id)
    else
      @transactions = ::Accounting::Transaction.all
    end

    @enable_export_to_csv = true

    @transactions_grid = initialize_grid(@transactions,
      enable_export_to_csv: @enable_export_to_csv,
      name: 'transactions'
    )

    export_grid_if_requested('transactions': 'admin/accounting/transactions/transactions_grid_definition')
  end
end
