Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.public_file_server.enabled = true
  config.action_controller.perform_caching = false
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
end
