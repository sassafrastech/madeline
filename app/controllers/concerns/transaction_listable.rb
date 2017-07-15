module TransactionListable
  extend ActiveSupport::Concern

  def initialize_transactions_grid(project_id = nil, order: 'txn_date desc, created_at desc')
    begin
      ::Accounting::Quickbooks::Updater.new.update
    rescue Accounting::Quickbooks::FullSyncRequiredError => e
      Rails.logger.error e
      settings = view_context.link_to(t('menu.settings'), admin_settings_path)
      flash.now[:error] = t('quickbooks.full_sync_required', settings: settings).html_safe
    rescue Quickbooks::ServiceUnavailable => e
      Rails.logger.error e
      flash.now[:error] = t('quickbooks.service_unavailable')
    rescue Quickbooks::MissingRealmError,
      Accounting::Quickbooks::NotConnectedError,
      Quickbooks::AuthorizationFailure => e
      Rails.logger.error e
      settings = view_context.link_to(t('menu.settings'), admin_settings_path)
      flash.now[:error] = t('quickbooks.authorization_failure', settings: settings, target: "_blank").html_safe
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
      @transactions = ::Accounting::Transaction.where(project_id: project_id).order(order)
    else
      @transactions = ::Accounting::Transaction.all.order(order)
    end

    @enable_export_to_csv = true

    @transactions_grid = initialize_grid(@transactions,
      enable_export_to_csv: @enable_export_to_csv,
      name: 'transactions'
    )

    export_grid_if_requested('transactions': 'admin/accounting/transactions/transactions_grid_definition')
  end

  def prep_transaction_form
    @loan_transaction_types = Accounting::Transaction::AVAILABLE_LOAN_TRANSACTION_TYPES
    @accounts = Accounting::Account.asset_accounts - Division.root.accounts
  end
end
