# Parent class for all Quickbooks task jobs
class QuickbooksJob < TaskJob
  rescue_from(Quickbooks::ServiceUnavailable) do |error|
    task.set_activity_message("error_quickbooks_unavailable")
    Accounting::LoanIssue.create!(level: :error, message: :quickbooks_unavailable)
    record_failure_and_raise_error(error)
  end
end
