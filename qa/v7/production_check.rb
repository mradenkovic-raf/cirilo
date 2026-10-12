# Isolated, disposable HTTP/CSRF check. Never opens the family database.
require "securerandom"
require "pathname"
project = Pathname.new(__dir__).join("../..").expand_path
qa_database = project.join("storage/v7-production.sqlite3").to_s
abort "Choose a fresh QA run: v7 production database already exists." if File.exist?(qa_database)
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

class ProductionRestartV7Check
  include ExerciseHelpers

  def initialize
    @http = ActionDispatch::Integration::Session.new(Rails.application)
    @http.host! "production-smoke.test"
    @learner = Learner.current
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
  end

  def reset(values, token: @token)
    @http.post("/progress/reset-all", params: values.merge(authenticity_token: token))
  end

  def run
    puts "FIXTURE: synthetic valid answers create 16 completed missions, four rescued friends, equipment and a battle."
    until @learner.reload.completed_missions >= 16
      complete_practice_session(PracticePlanner.start!(@learner))
    end
    completed = @learner.practice_sessions.where(status: "completed").order(:id).last
    battle = BattleArena.start!(@learner, completed)
    active = PracticePlanner.start!(@learner)
    old_answer = correct_attributes(active.current_exercise)
    ShopService.new(@learner).purchase!(item_id: "theme_space", generation: @learner.shop_generation)
    @learner.letter_confusions.create!(expected_letter_id: "a", chosen_letter_id: "m", observations: 2, last_mistake_at: Time.current)
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    check(@learner.reload.can_restore_dino?, "fixture contains recoverable old equipment")
    get("/workshop")
    check(@document.css("[data-rescued-friend]").length == 4, "workshop shows exactly four rescued friends")
    get("/progress")
    form = @document.at_css('form[action="/progress/reset-all"]')
    check(form.present?, "parent has separate full restart form")
    check(@token.present? && ActionController::Base.allow_forgery_protection, "CSRF protection enabled")
    values = { confirm_reset: "1", reset_word: "RESET", shop_generation: @learner.shop_generation,
      dinosaur_generation: @learner.dinosaur_generation }
    before = @learner.attributes
    reset(values, token: "invalid-token")
    check(@http.response.status == 422 && @learner.reload.attributes == before, "invalid CSRF cannot erase progress")
    reset(values.merge(reset_word: "wrong"))
    check(@http.response.status == 303 && @learner.reload.attributes == before, "wrong confirmation cannot erase progress")
    get("/progress")
    reset(values)
    check(@http.response.status == 303, "valid full restart redirects")
    check(@learner.reload.values_at(:xp, :xp_spent, :completed_missions) == [0, 0, 0], "points and map reset to zero")
    check(@learner.values_at(:selected_dino, :dino_color, :selected_theme, :selected_effect) == %w[rex green meadow stars], "appearance resets to defaults")
    check(@learner.last_dino_snapshot.empty? && !@learner.can_restore_dino?, "old equipment snapshot cannot restore erased state")
    %i[attempts battles part_unlocks practice_sessions letter_progresses letter_confusions shop_purchases].each do |relation|
      check(@learner.public_send(relation).count.zero?, "#{relation} cleared")
    end
    check(@learner.shop_generation == values[:shop_generation] + 1 && @learner.dinosaur_generation == values[:dinosaur_generation] + 1, "both stale-form generations advanced")
    get("/adventure")
    check(AdventureMap.new(@learner).rescued_count.zero?, "no rescued friends after full restart")
    get("/workshop")
    check(@document.css("[data-rescued-friend]").empty?, "workshop no longer shows rescued friends")
    get("/shop")
    get("/progress")
    @http.post("/practice_sessions/#{active.id}/attempts", params: old_answer, as: :json, headers: { "X-CSRF-Token" => @token })
    check(@http.response.status == 404, "old answer endpoint rejects erased mission")
    @http.post("/battles/#{battle.id}/moves", params: { move: "attack", expected_round: 0, expected_revision: 0 }, as: :json, headers: { "X-CSRF-Token" => @token })
    check(@http.response.status == 404, "old battle endpoint rejects erased match")
    @http.post("/workshop/restore-dino", params: { authenticity_token: @token, dinosaur_generation: values[:dinosaur_generation] })
    check(@http.response.status == 303 && @learner.part_unlocks.count.zero?, "old restore form cannot bring back equipment")
    get("/")
    @http.post("/practice_sessions", params: { authenticity_token: @token })
    check(@http.response.status == 303, "new first mission starts after reset")
    fresh = @learner.active_session
    check(fresh.id > active.id && fresh.cursor.zero? && fresh.focus_letters == Curriculum.ordered_letters.first(3).map { |letter| letter.fetch("id") }, "fresh learning starts with initial letters and new IDs")
    solve_current_exercise(fresh)
    check(@learner.reload.xp == 10, "new answer awards fresh XP")
    get("/progress")
    reset(values)
    check(@http.response.status == 303 && @learner.reload.xp == 10 && @learner.active_session.id == fresh.id, "replayed reset cannot erase new progress")
    puts "PRODUCTION V7: PASS; isolated Rails/Rack with real CSRF, synthetic learning. Family database untouched."
  end
end

ProductionRestartV7Check.new.run
