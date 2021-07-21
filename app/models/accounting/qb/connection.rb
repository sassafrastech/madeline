# Stores the access token and other necessary information necessary to authenticate
# Quickbooks API requests.
# Also responsible for determining if connection is still valid or expired.
class Accounting::QB::Connection < ApplicationRecord
  belongs_to :division

  QB_AUTH_LOG_TAG = "QBAuth"

  def connected?
    !expired? && !invalid_grant
  end

  def auth_details
    {access_token: token, company_id: realm_id}
  end

  def token
    qb_access_token = self.access_token
    qb_refresh_token = self.refresh_token
    qb_consumer = Accounting::QB::Consumer.new.oauth_consumer
    oauth2_token = OAuth2::AccessToken.new(qb_consumer, qb_access_token, {:refresh_token => qb_refresh_token})
    oauth2_token
  end

  def company_name
    begin
      company_info_service = ::Quickbooks::Service::CompanyInfo.new(self.auth_details)
      query_result = company_info_service.query("select * from CompanyInfo")
      if query_result.entries.present?
        query_result.entries.first.company_name
      else
        "Unknown"
      end
    rescue StandardError
      # don't handle error if unable to get company name
      "Unknown"
    end
  end

  def log_token_info(message)
    token_info = "Access token: #{self.access_token}\n
      Refresh token: #{self.refresh_token}\n
      Access token expires at: #{self.token_expires_at}"
    Rails.logger.tagged(QB_AUTH_LOG_TAG) { Rails.logger.debug("#{message}:\n #{token_info}") }
  end

  private

  def expired?
    if token_expires_at < Time.current
      refresh_token!
      return token_expires_at < Time.current
    else
      false
    end
  end

  def refresh_token!
    log_token_info("About to refresh token")
    qb_consumer = Accounting::QB::Consumer.new.oauth_consumer
    oauth2_token = OAuth2::AccessToken.new(
      qb_consumer,
      self.access_token,
      {refresh_token: self.refresh_token}
    )
    begin
      refreshed = oauth2_token.refresh!.to_hash
    rescue OAuth2::Error
      log_token_info("OAuth2 error when refreshing token. Old token info")
      self.invalid_grant = true
      return false
    else
      self.access_token = refreshed[:access_token]
      self.refresh_token = refreshed[:refresh_token]
      self.token_expires_at = Time.zone.at(refreshed[:expires_at])
      self.invalid_grant = false
      # last_updated_at is not updated, because no new accounting data pulled from qb
      self.save!
      log_token_info("Successfully refreshed token")
      return true
    end
  end
end
