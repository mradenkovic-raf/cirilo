# Run after preparing a fresh storage/v18-production.sqlite3. This check never
# uses the family database. Its two child processes simulate a Railway restart;
# Rack requests exercise production middleware, not a live TLS proxy/container.
require_relative "../../config/boot"
require "json"
require "securerandom"
require "tmpdir"
require "rbconfig"

root = File.expand_path("../..", __dir__)
database = File.join(root, "storage/v18-production.sqlite3")
if ENV["DATABASE_PATH"] && File.expand_path(ENV.fetch("DATABASE_PATH"), root) != database
  abort "Use only storage/v18-production.sqlite3 for this check"
end
ENV["DATABASE_PATH"] = database
ENV["RAILS_ENV"] = "production"
ENV["APP_HOST"] ||= "qa-cirilo.up.railway.app"
ENV["ASSUME_SSL"] = "1"
ENV["FORCE_SSL"] = "1"
ENV["RAILS_LOG_LEVEL"] = "fatal"

mode = ARGV.fetch(0, "run")
unless %w[run write restore].include?(mode)
  abort "Usage: ruby qa/v18/production_check.rb"
end

if mode == "run"
  ENV["SECRET_KEY_BASE"] ||= SecureRandom.hex(64)
  Dir.mktmpdir("v18-production-check-", File.join(root, "tmp")) do |directory|
    state_path = File.join(directory, "browser.json")
    %w[write restore].each do |phase|
      pid = Process.spawn(RbConfig.ruby, __FILE__, phase, state_path, chdir: root)
      _, status = Process.wait2(pid)
      abort "Production check failed in #{phase} phase" unless status.success?
    end
  end
  puts JSON.pretty_generate(result: "PASS", environment: "production", browsers: 2,
    rails_processes: 2, database: "storage/v18-production.sqlite3",
    checks: ["Railway /up without learner or cookie", "allowed host behind HTTPS proxy",
      "unknown host blocked", "Secure + HttpOnly + SameSite cookie", "private pages no-store",
      "real CSRF form and answer submission", "missing CSRF rejected", "foreign mission 404",
      "independent browser progress", "persistent cookie and earned XP survive a new Rails process"])
  exit
end

ENV.fetch("SECRET_KEY_BASE")
state_path = ARGV.fetch(1)
require_relative "../../config/environment"
require "action_dispatch/testing/integration"

def verify(condition, message)
  raise message unless condition
end

def browser(host: ENV.fetch("APP_HOST"), proxy: true)
  # Keep the browser-facing URL HTTPS so its real Secure cookie jar works, then
  # hand Rails the HTTP connection that a TLS-terminating proxy would make.
  app = if proxy
    ->(env) { Rails.application.call(env.merge("HTTPS" => "off", "rack.url_scheme" => "http")) }
  else
    Rails.application
  end
  ActionDispatch::Integration::Session.new(app).tap do |client|
    client.host! host
    client.https! proxy
  end
end

def proxy_headers
  { "X-Forwarded-Proto" => "https" }
end

def csrf(client)
  token = Nokogiri::HTML(client.response.body).at_css('meta[name="csrf-token"]')
  verify(token.present?, "CSRF form token missing")
  token["content"]
end

def healthcheck
  before = Learner.count
  client = browser(host: "healthcheck.railway.app", proxy: false)
  client.get "/up"
  verify(client.response.status == 200, "Railway healthcheck failed or redirected")
  verify(Learner.count == before, "Healthcheck created a learner")
  verify(client.response.headers["set-cookie"].blank?, "Healthcheck created a cookie")
end

healthcheck

if mode == "write"
  verify(Learner.count.zero?, "Use a fresh QA database")
  stranger = browser(host: "untrusted.example")
  stranger.get "/", headers: proxy_headers
  verify(stranger.response.status == 403 && Learner.count.zero?, "Unknown host accepted")

  first = browser
  first.get "/", headers: proxy_headers
  verify(first.response.status == 200, "Valid host failed or redirected behind HTTPS proxy")
  first_learner = Learner.sole
  cookie_header = Array(first.response.headers["set-cookie"]).find { |value| value.start_with?("cirilo_device=") }
  verify(cookie_header&.match?(/; secure/i) && cookie_header.match?(/; httponly/i) &&
    cookie_header.match?(/; samesite=lax/i), "Protected browser cookie missing")
  verify(first.response.headers["Cache-Control"].include?("no-store"), "Personal page may be cached")
  first.post "/practice_sessions", params: { authenticity_token: csrf(first) }, headers: proxy_headers
  verify(first.response.status == 303, "CSRF-enabled mission creation failed")
  mission = first_learner.practice_sessions.sole
  first.get "/practice_sessions/#{mission.id}", headers: proxy_headers
  exercise = mission.current_exercise
  verify(exercise.fetch("kind") == "read_word", "Expected a reading task for progress check")
  first.post "/practice_sessions/#{mission.id}/attempts", as: :json,
    headers: proxy_headers.merge("X-CSRF-Token" => csrf(first)),
    params: { exercise_id: exercise.fetch("id"), answer: exercise.fetch("answer") }
  verify(first.response.status == 200 && mission.reload.cursor == 1 &&
    first_learner.reload.xp == AttemptRecorder::TASK_XP, "Answer did not persist earned progress")

  first.get "/workshop", headers: proxy_headers
  first.patch "/workshop", params: { authenticity_token: csrf(first),
    dino_color: "blue", shop_generation: first_learner.shop_generation }, headers: proxy_headers
  verify(first.response.status == 303 && first_learner.reload.dino_color == "blue", "Own customization failed")

  second = browser
  second.get "/", headers: proxy_headers
  verify(second.response.status == 200 && Learner.count == 2, "Browsers must be independent")
  second_learner = Learner.where.not(id: first_learner.id).sole
  second.get "/practice_sessions/#{mission.id}", headers: proxy_headers
  verify(second.response.status == 404, "Foreign mission leaked")
  verify(second_learner.reload.xp.zero? && second_learner.dino_color == "green" &&
    second_learner.practice_sessions.count.zero?, "Progress crossed browser boundary")

  first.post "/practice_sessions", headers: proxy_headers
  verify(first.response.status == 422 && first_learner.practice_sessions.count == 1, "CSRF-free write accepted")

  File.open(state_path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
    file.write(JSON.generate(learner_id: first_learner.id, second_id: second_learner.id,
      mission_id: mission.id, cookie: first.cookies[:cirilo_device],
      second_cookie: second.cookies[:cirilo_device]))
  end
else
  state = JSON.parse(File.read(state_path))
  verify(Learner.count == 2, "Persisted learners missing after restart")
  reopened = browser
  reopened.cookies[:cirilo_device] = state.fetch("cookie")
  reopened.get "/practice_sessions/#{state.fetch('mission_id')}", headers: proxy_headers
  verify(reopened.response.status == 200 && Learner.count == 2, "Persistent cookie failed after restart")
  learner = Learner.find(state.fetch("learner_id"))
  mission = learner.practice_sessions.find(state.fetch("mission_id"))
  verify(learner.xp == AttemptRecorder::TASK_XP && learner.dino_color == "blue" &&
    mission.cursor == 1 && mission.attempts.where(correct: true).count == 1, "Earned progress changed after restart")

  other = browser
  other.cookies[:cirilo_device] = state.fetch("second_cookie")
  other.get "/", headers: proxy_headers
  verify(other.response.status == 200 && Learner.count == 2, "Second cookie failed after restart")
  other.get "/practice_sessions/#{mission.id}", headers: proxy_headers
  verify(other.response.status == 404 && Learner.find(state.fetch("second_id")).xp.zero?,
    "Browser isolation failed after restart")
end
