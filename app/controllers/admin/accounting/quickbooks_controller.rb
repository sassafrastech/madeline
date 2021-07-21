class Admin::Accounting::QuickbooksController < Admin::AdminController
  # Kicks off oauth flow by redirecting to Intuit with request token.
  def authenticate
    authorize :'accounting/quickbooks', :authenticate?
    if Rails.env.test?
      redirect_to oauth_callback_admin_accounting_quickbooks_path(state: "test_state", realmId: "test_realm_id")
    else
      redirect_uri = oauth_callback_admin_accounting_quickbooks_url
      grant_url = qb_consumer.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        response_type: "code",
        state: SecureRandom.hex(12),
        scope: "com.intuit.quickbooks.accounting"
      )

      redirect_to grant_url
    end
  end

  def oauth_callback
    authorize :'accounting/quickbooks', :oauth_callback?
    @header_disabled = true

    # Fetch and store the access token and other necessary authentication information.
    if params[:state]
      response = oauth_token_response
      raise "OAuth token response nil" if response.blank?

      connection = Accounting::QB::Connection.first
      connection_attrs = {
        access_token: response.token,
        invalid_grant: false,
        refresh_token: response.refresh_token,
        realm_id: params[:realmId],
        division: Division.root,
        token_expires_at: Time.zone.at(response.expires_at)
        # last_updated_at is not updated, because no new accounting data pulled from qb
      }
      connection ||= Accounting::QB::Connection.new
      connection.update(connection_attrs)
      connection.save!
      connection.log_token_info("OAuth connection updated in OAuth callback")
    end

    Task.create(
      job_class: QuickbooksFullFetcherJob,
      job_type_value: :full_fetcher,
      activity_message_value: 'fetching_quickbooks_data'
    ).enqueue(job_params: {division_id: current_division.qb_division.id})

    flash[:notice] = t('quickbooks.connection.link_message')
    flash[:alert] = t('quickbooks.connection.import_in_progress_message')
    redirect_to admin_accounting_settings_path
  end

  def disconnect
    authorize :'accounting/quickbooks', :disconnect?
    Division.root.qb_connection.destroy
    redirect_to admin_accounting_settings_path, notice: t('quickbooks.connection.disconnect_message')
  end

  def update_changed
    authorize :'accounting/quickbooks', :update?
    @task = Task.create(
      job_class: FetchQuickbooksChangesJob,
      job_type_value: 'fetch_quickbooks_changes',
      activity_message_value: 'task_enqueued'
    ).enqueue

    flash[:notice] = t("quickbooks.update.update_queued_html", url: admin_task_path(@task))

    redirect_back(fallback_location: admin_loans_path)
  end

  private

  def qb_consumer
    @qb_consumer ||= Accounting::QB::Consumer.new
  end

  def oauth_token_response
    if Rails.env.test?
      OpenStruct.new(
        token: "test_access_token",
        refresh_token: "test_refresh_token",
        expires_at: Time.current + 1.hour
      )
    else
      redirect_uri = oauth_callback_admin_accounting_quickbooks_url
      qb_consumer.auth_code.get_token(params[:code], redirect_uri: redirect_uri)
    end
  end
end
