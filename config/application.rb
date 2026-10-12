require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)

module Cirilo
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "Belgrade"
    config.generators.system_tests = nil
    config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"
  end
end
