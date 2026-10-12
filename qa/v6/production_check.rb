# Fresh synthetic production database; never opens the family's database.
require "securerandom"
require "pathname"
project = Pathname.new(__dir__).join("../..").expand_path
qa_database = project.join("storage/v6-production.sqlite3").to_s
abort "Choose a fresh QA run: v6 production database already exists." if File.exist?(qa_database)
ENV["RAILS_ENV"] = "production"
ENV["DATABASE_PATH"] = qa_database
ENV.delete("DATABASE_URL")
ENV["APP_HOST"] = "production-smoke.test"
ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
ENV["RAILS_LOG_LEVEL"] = "warn"
ENV["FORCE_SSL"] = "0"
ENV["ASSUME_SSL"] = "0"
require_relative "../../config/environment"
require "action_dispatch/testing/integration"
require_relative "../../test/services/exercise_helpers"
abort "Wrong QA database" unless Rails.env.production? && ActiveRecord::Base.connection_db_config.database == qa_database
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate

class ProductionAdventureV6Check
  include ExerciseHelpers

  def initialize
    @http = ActionDispatch::Integration::Session.new(Rails.application)
    @http.host! "production-smoke.test"
    @learner = Learner.current
    @assets = []
  end

  def check(value, description)
    raise "FAIL #{description}" unless value
    puts "PASS #{description}"
  end

  def get(path)
    @http.get(path)
    check(@http.response.status == 200, "GET #{path} -> 200")
    @document = Nokogiri::HTML(@http.response.body)
    @token = @document.at_css('meta[name="csrf-token"]')&.[]("content") || @token
    @assets.concat(@document.css('link[rel="stylesheet"]').map { |n| n["href"] })
    @assets.concat(@document.css('script[src]').map { |n| n["src"] })
  end

  def post_json(path, values, status: 200)
    @http.post(path, params: values, as: :json, headers: { "X-CSRF-Token" => @token })
    check(@http.response.status == status, "POST #{path} -> #{status}")
    JSON.parse(@http.response.body)
  end

  def run
    get("/")
    check(@token.present?, "CSRF enabled")
    get("/adventure")
    get("/workshop")
    get("/shop")
    get("/alphabet")
    get("/progress")
    @http.post("/practice_sessions", params: { authenticity_token: @token })
    check(@http.response.status == 303, "new mission through HTTP")
    mission = @learner.active_session
    first = nil
    kinds = []
    until mission.reload.completed?
      exercise = mission.current_exercise
      kinds << exercise.fetch("kind")
      get("/practice_sessions/#{mission.id}")
      if exercise.fetch("kind") == "story_action"
        check(@document.css('button[data-answer]').length == 4, "story renders four choices")
      end
      if exercise.fetch("kind") == "memory_word"
        post_json("/practice_sessions/#{mission.id}/memorize", { exercise_id: exercise.fetch("id") })
      end
      attrs = correct_attributes(exercise)
      first ||= attrs
      result = post_json("/practice_sessions/#{mission.id}/attempts", attrs)
      check(result.fetch("correct"), "#{exercise.fetch('kind')} accepts synthetic correct answer")
    end
    check(kinds.include?("story_action") && kinds.length == 12, "12 regular tasks include comprehension story")
    check(@learner.reload.xp == 145 && mission.earned_xp == 145, "mission awards exactly 145 XP")
    replay = post_json("/practice_sessions/#{mission.id}/attempts", first)
    check(replay.fetch("duplicate") && replay.fetch("xp_earned").zero? && @learner.reload.xp == 145, "replayed answer does not duplicate rewards")
    get("/practice_sessions/#{mission.id}")
    get("/adventure")

    puts "FIXTURE: remaining missions completed with synthetic valid answers for full equipment."
    until @learner.reload.completed_missions >= 12
      complete_practice_session(PracticePlanner.start!(@learner))
    end
    completed = @learner.practice_sessions.where(status: "completed").order(:id).last
    get("/practice_sessions/#{completed.id}")
    get("/adventure")
    @http.post("/practice_sessions/#{completed.id}/battle", params: { authenticity_token: @token })
    check(@http.response.status == 303, "battle starts through HTTP")
    battle = completed.reload.battle
    check(battle.player_max_hp == 15 && battle.enemy_max_hp == 12, "existing equipment health rules preserved")
    get("/battles/#{battle.id}")
    check_powers(battle)

    @assets.uniq.each do |path|
      @http.get(path)
      check(@http.response.status == 200, "versioned asset #{path.split('?').first}")
    end
    check(@learner.reload.completed_missions == 12 && @learner.xp == 1740 && @learner.xp_spent.zero?, "battle and map do not change wallet or completed missions")
    puts "PRODUCTION V6: PASS; Rails/Rack with CSRF, synthetic answers; no physical phone or public hosting."
  end

  def check_powers(battle)
    state = BattleArena.state(battle)
    goggles = { power: "goggles", expected_round: state.fetch(:round), expected_revision: state.fetch(:action_revision) }
    state = post_json("/battles/#{battle.id}/powers", goggles)
    revealed = state.fetch("revealed_enemy_move")
    check(BattleArena::MOVES.include?(revealed), "goggles reveal a committed enemy move")
    get("/battles/#{battle.id}")
    check(BattleArena.state(battle.reload).fetch(:revealed_enemy_move) == revealed, "revealed move survives page reload")
    repeated = post_json("/battles/#{battle.id}/powers", goggles)
    check(repeated.fetch("duplicate") && repeated.fetch("action_revision") == state.fetch("action_revision"), "repeated goggles do not spend another action")
    post_json("/battles/#{battle.id}/powers", goggles.merge(power: "shield"), status: 409)
    state = post_json("/battles/#{battle.id}/powers", {
      power: "shield", expected_round: state.fetch("round"), expected_revision: state.fetch("action_revision")
    })
    check(state.fetch("shield_armed"), "shield is armed")
    hp = state.fetch("player_hp")
    state = post_json("/battles/#{battle.id}/moves", {
      move: BattleArena::BEATS.fetch(revealed), expected_round: state.fetch("round"),
      expected_revision: state.fetch("action_revision")
    })
    check(state.fetch("outcome") == "blocked" && state.fetch("player_hp") == hp && !state.fetch("shield_armed"), "shield absorbs one guaranteed incoming hit")
    check(state["revealed_enemy_move"].nil?, "next enemy move stays hidden")
    rockets = { power: "rockets", expected_round: state.fetch("round"), expected_revision: state.fetch("action_revision") }
    enemy_hp = state.fetch("enemy_hp")
    state = post_json("/battles/#{battle.id}/powers", rockets)
    check(state.fetch("outcome") == "dodge" && state.fetch("player_hp") == hp && state.fetch("enemy_hp") == enemy_hp, "rockets skip a round without damage")
    repeated = post_json("/battles/#{battle.id}/powers", rockets)
    check(repeated.fetch("duplicate") && repeated.fetch("round") == state.fetch("round"), "repeated rockets do not advance another round")
    get("/battles/#{battle.id}")
    check(state.fetch("powers").values.all? { |power| power.fetch("used") && !power.fetch("available") }, "all three charges consumed once")
  end
end

ProductionAdventureV6Check.new.run
