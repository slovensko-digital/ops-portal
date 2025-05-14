require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ops
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("vendor", "stylesheets")

    config.i18n.default_locale = :sk
    config.i18n.available_locales = [ :en, :sk ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Bratislava"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :good_job

    config.good_job.smaller_number_is_higher_priority = true
    config.good_job.cleanup_preserved_jobs_before_seconds_ago = 1.days
    config.good_job.cleanup_discarded_jobs = false

    config.active_record.schema_format = :sql

    config.exceptions_app = routes
  end
end
