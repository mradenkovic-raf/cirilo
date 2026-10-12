Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = true
  config.assume_ssl = ENV["ASSUME_SSL"] == "1"
  config.force_ssl = ENV["FORCE_SSL"] == "1"
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
  config.active_record.dump_schema_after_migration = false
end
