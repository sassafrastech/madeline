require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MadelineSystem
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Additional paths to autoload
    config.eager_load_paths << "#{Rails.root}/lib"

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir["#{Rails.root.to_s}/config/locales/**/*.{rb,yml}"]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :sidekiq

    config.action_mailer.default_url_options = { host: ENV['MADELINE_HOSTNAME'] }

    # Send email on errors
    unless Rails.env.test? || Rails.env.development?
      Rails.application.config.middleware.use ExceptionNotification::Rack, email: {
        email_prefix: "[Madeline #{Rails.env.to_s.capitalize}] ",
        sender_address: %{"Madeline" <#{ENV['MADELINE_EMAIL_FROM']}>},
        exception_recipients: [ENV['MADELINE_ERROR_EMAILS_TO']]
      }
    end

    config.generators do |g|
      g.fixture_replacement :factory_bot, suffix: 'factory'
    end
  end

  # This seems to be required for proper rendering of all wice_grid views. (Without, view contents is all html escaped.)
  Slim::Engine.set_options pretty: true, sort_attrs: false
end

puts "Rails.env: #{Rails.env}"
puts "database: #{MadelineSystem::Application.config.database_configuration[::Rails.env]['database']}"
