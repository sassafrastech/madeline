class QuickbooksUpdateJob < QuickbooksJob
  attr_accessor :updater

  def perform(_job_params)
    # Delete only global issues now before fetch phase but keep loan-specific
    # issues so that if fetch we still hide those loans' txn data appropriately.
    Accounting::SyncIssue.global.delete_all
    self.updater = Accounting::QB::Updater.new
    started_update_at = Time.zone.current
    updater.qb_sync_for_loan_update
    task.set_activity_message("syncing_with_quickbooks")
    loans.each_with_index do |loan, index|
      task.set_activity_message("updating_loans", so_far: (index), total: loans.count)
      begin
        updater.update_loan(loan)
      rescue Accounting::QB::UnprocessableAccountError => e
        Accounting::SyncIssue.create!(loan: e.loan, accounting_transaction: e.transaction,
                                      message: :unprocessable_account, level: :error, custom_data: {})
      rescue Quickbooks::ServiceUnavailable
        # This is an error b/c we may have been in the middle of creating interest txns
        Accounting::SyncIssue.create!(level: :error, loan: loan, message: :quickbooks_unavailable_recalc)
        raise # If QB is down, no point in continuing, so re-raise
      rescue StandardError => e
        # If there is an unhandled error updating an individual loan, we don't want the whole process to fail.
        # We let the user know that there was a system error and we've been notified.
        # But we don't expose the original error message to the user since it won't be intelligble
        # and could be a security issue.
        Accounting::SyncIssue.create!(level: :error, loan: loan, message: :system_error_recalc)

        # We want to receive a loud notification about an unhandled error.
        # If we find this is often generating a lot of similar errors
        # then we should really start using Sentry or some other service to group them.
        notify_of_error(e, data: {context: "Unhandled error during loan update", loan_id: loan.id})
      end
    end

    # TODO: This is duplicated in Updater#update and needs to be DRYed up.
    # We record last_updated_at as the time this update started. The user-prompted ways
    # the update is started are used by only admins and rarely.
    updater.qb_connection.update_attribute(:last_updated_at, started_update_at)

    # Even if there have been per-loan errors, we still consider the task completed.
    # If there were per-loan errors that support team needs to be notified of, those notices get sent when
    # the errors are handled.
    task.set_activity_message("completed")
  end

  rescue_from(Accounting::QB::DataResetRequiredError) do |error|
    Accounting::SyncIssue.create!(level: :warning, message: :data_reset_required)
    record_failure_and_raise_error(error, message: "error_data_reset_required")
  end

  rescue_from(Accounting::QB::AccountsNotSelectedError) do |error|
    Accounting::SyncIssue.create!(level: :warning, message: :quickbooks_accounts_not_selected)
    record_failure_and_raise_error(error, message: "error_quickbooks_accounts_not_selected")
  end

  protected

  def divisions
    @divisions ||= Division.qb_accessible_divisions
  end
end
