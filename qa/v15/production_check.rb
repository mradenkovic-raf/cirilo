# Runs only against a fresh, isolated QA database; never the family database.
require_relative "../../config/boot"
require "securerandom"
require "json"
ENV["RAILS_ENV"] = "production"
ENV["DATABASE_PATH"] = File.expand_path("../../storage/v15-production.sqlite3", __dir__)
ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
ENV["ASSUME_SSL"] = "1"
ENV["FORCE_SSL"] = "1"
ENV["RAILS_LOG_LEVEL"] = "fatal"
require_relative "../../config/environment"
require "action_dispatch/testing/integration"

def verify(condition, message)
  raise message unless condition
end

def browser
  ActionDispatch::Integration::Session.new(Rails.application).tap(&:https!)
end

def csrf(client)
  Nokogiri::HTML(client.response.body).at_css('meta[name="csrf-token"]')["content"]
end

verify(Learner.count.zero?, "Use a fresh QA database")
first = browser
first.get "/"
verify(first.response.status == 200, "First browser failed")
first_learner = Learner.sole
device_header = Array(first.response.headers["set-cookie"]).find { |h| h.start_with?("cirilo_device=") }
verify(device_header&.match?(/; secure/i) && device_header.match?(/; httponly/i), "Protected HTTPS cookie missing")
verify(first.response.headers["Cache-Control"].include?("no-store"), "Personal page may be cached")
first.post "/practice_sessions", params: { authenticity_token: csrf(first) }
verify(first.response.status == 303, "CSRF-enabled mission creation failed")
mission = first_learner.practice_sessions.sole

second = browser
second.get "/"
verify(second.response.status == 200 && Learner.count == 2, "Browsers must be independent")
second_learner = Learner.where.not(id: first_learner.id).sole
second.get "/practice_sessions/#{mission.id}"
verify(second.response.status == 404, "Foreign mission leaked")

first.get "/workshop"
first.patch "/workshop", params: {
  authenticity_token: csrf(first), dino_color: "blue", shop_generation: 1
}
verify(first.response.status == 303 && first_learner.reload.dino_color == "blue", "Own customization failed")
verify(second_learner.reload.dino_color == "green", "Customization crossed browser boundary")

reopened = browser
reopened.cookies[:cirilo_device] = first.cookies[:cirilo_device]
reopened.get "/practice_sessions/#{mission.id}"
verify(reopened.response.status == 200 && Learner.count == 2, "Persistent key did not restore mission")
reopened.post "/practice_sessions"
verify(reopened.response.status == 422 && first_learner.practice_sessions.count == 1, "CSRF-free write accepted")

puts JSON.pretty_generate(result: "PASS", environment: Rails.env, browsers: 2,
  checks: ["Secure + HttpOnly HTTPS cookie", "private pages no-store", "real CSRF form submission",
    "foreign mission 404", "own appearance change", "other browser unchanged",
    "same mission with only persistent cookie", "missing CSRF rejected"])
