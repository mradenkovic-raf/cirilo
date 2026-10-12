# Only synthetic data in this dedicated QA database may be changed by this script.
require "securerandom"
require "digest"
require "pathname"

project = Pathname.new(__dir__).join("../..").expand_path
qa_database = project.join("storage/v5-production.sqlite3").to_s
abort "QA database already exists; choose a fresh isolated run before retrying." if File.exist?(qa_database)
ENV["RAILS_ENV"] = "production"
ENV["DATABASE_PATH"] = qa_database
ENV.delete("DATABASE_URL")
ENV["APP_HOST"] = "production-smoke.test"
ENV["SECRET_KEY_BASE"] = SecureRandom.hex(64)
ENV["RAILS_LOG_LEVEL"] = "warn"
ENV["FORCE_SSL"] = "0"
ENV["ASSUME_SSL"] = "0"

protected_paths = %w[storage/development.sqlite3 storage/test.sqlite3].map { |name| project.join(name) }
before = protected_paths.to_h { |path| [path.to_s, Digest::SHA256.file(path).hexdigest] }
require_relative "../../config/environment"
require "action_dispatch/testing/integration"
require_relative "../../test/services/exercise_helpers"

unless Rails.env.production? && ActiveRecord::Base.connection_db_config.database == qa_database
  abort "Refusing to use a database other than the dedicated v5 production QA database."
end
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate

class ProductionShopV5Check
  include ExerciseHelpers

  def initialize
    @http = ActionDispatch::Integration::Session.new(Rails.application)
    @http.host! "production-smoke.test"
    @learner = Learner.current
  end

  def check(value, message)
    raise "FAIL #{message}" unless value
    puts "PASS #{message}"
  end

  def get(path)
    @http.get(path)
    check(@http.response.status == 200, "GET #{path} -> 200")
    @document = Nokogiri::HTML(@http.response.body)
    @token = @document.at_css('meta[name="csrf-token"]')&.[]("content") || @token
  end

  def form(path, values)
    @http.post(path, params: values.merge(authenticity_token: @token))
    check(@http.response.status == 303, "POST #{path} -> 303")
  end

  def purchase(id, generation: 1)
    form("/shop/purchases", item_id: id, shop_generation: generation)
    check(@http.response.location.end_with?("#shop-#{ShopCatalog.find(id).fetch('category')}"), "redirect zadrzava kategoriju")
  end

  def attempt(session, attributes)
    @http.post("/practice_sessions/#{session.id}/attempts", params: attributes,
      as: :json, headers: { "X-CSRF-Token" => @token })
    check(@http.response.status == 200, "POST odgovor -> 200 sa CSRF tokenom")
    JSON.parse(@http.response.body)
  end

  def reset(values = {})
    form("/progress/reset-shop", { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 }.merge(values))
  end

  def history
    [@learner.reload.completed_missions, @learner.letter_progresses.order(:id).map(&:attributes),
      @learner.practice_sessions.order(:id).map(&:attributes), @learner.attempts.order(:id).map(&:attributes),
      @learner.part_unlocks.order(:id).map(&:attributes), @learner.battles.order(:id).map(&:attributes)]
  end

  def run
    puts "FIXTURE: sintetickih 2000 XP, jedna istorijska misija i jedan deo; bez stvarnog decjeg napretka."
    @learner.update!(xp: 2000, completed_missions: 1)
    completed = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    @learner.part_unlocks.create!(practice_session: completed, part_key: "boots", position: 1)
    active = PracticePlanner.start!(@learner)
    first_attributes = correct_attributes(active.current_exercise)

    get("/shop")
    check(@document.css("[data-shop-card]").length == 17, "svih 17 shop izbora postoji")
    check(@token.present?, "CSRF token postoji; zastita nije iskljucena")
    initial_answer = attempt(active, first_attributes)
    check(initial_answer.fetch("xp_balance") == 2010, "prvi sinteticki validan odgovor daje 10 XP")

    purchase("dino_robo")
    check(@learner.reload.xp_balance == 2010 && @learner.shop_purchases.empty?, "Robo ne moze da preskoci prethodnike")
    purchase("dino_tricera")
    check(@learner.reload.xp_balance == 1770, "Tricera kosta 240 XP")
    purchase("dino_robo")
    check(@learner.reload.xp_balance == 1770, "i dalje je potreban Stego")
    purchase("dino_stego")
    purchase("dino_robo")
    purchase("color_ice")
    purchase("color_lava")
    check(@learner.reload.xp_balance == 510 && @learner.selected_dino == "robo" && @learner.dino_color == "lava", "kupovina redom radi; ukupni XP ostaje 2010")
    battle = BattleArena.start!(@learner, completed)
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    get("/progress")
    check(@document.css('form[action="/progress/reset-shop"] input[name="reset_word"][required]').one?, "roditeljski reset zahteva typed RESET")
    check(@document.css('form[action="/progress/reset-shop"] input[name="confirm_reset"][required]').one?, "roditeljski reset zahteva potvrdu")
    get("/workshop")
    check(@document.css(".parent-reset").empty?, "roditeljski reset nije na decjoj radionici")
    reset(reset_word: "reset")
    check(@learner.reload.xp_balance == 510, "pogresna potvrda ne menja novcanik")

    before_reset = history
    reset
    check(@learner.reload.values_at(:xp, :xp_spent, :shop_generation) == [0, 0, 2], "XP i potrosnja su 0, generacija je 2")
    check(@learner.level == 1 && @learner.shop_purchases.empty?, "nivo 1 i obrisane kupovine")
    check(@learner.values_at(:selected_dino, :dino_color, :selected_theme, :selected_effect) == %w[rex green meadow stars], "vraceni svi pocetni izbori")
    check(before_reset == history, "ucenje, odgovori, misije, oprema i borbe sacuvani")
    replay = attempt(active, first_attributes)
    check(replay.fetch("duplicate") && replay.fetch("xp_balance").zero? && replay.fetch("xp_earned").zero?, "stari odgovor ne vraca XP posle reseta")
    next_answer = attempt(active, correct_attributes(active.reload.current_exercise))
    check(next_answer.fetch("xp_balance") == 10, "tekuci zadatak posle reseta ponovo zaradjuje 10 XP")
    reset
    check(@learner.reload.xp_balance == 10 && @learner.shop_generation == 2, "ponovljen stari reset ne brise novi XP")
    DinoReset.restore!(@learner, generation: @learner.dinosaur_generation)
    check(@learner.reload.dino_color == "green" && @learner.part_unlocks.count == 1, "stara oprema moze da se vrati, obrisana kupovna lava ne moze")
    check(battle.reload.values_at(:dino_species, :dino_color) == %w[robo lava], "istorijska borba zadrzava svoj snimak")

    puts "FIXTURE: za proveru starih formulara sada postavljeno 500 XP u istoj izolovanoj bazi."
    @learner.update!(xp: 500)
    purchase("dino_tricera", generation: 1)
    check(@learner.reload.xp_balance == 500 && @learner.shop_purchases.empty?, "stara kupovna forma odbijena i uz dovoljan budzet")
    @http.patch("/shop/equip", params: { item_id: "color_blue", shop_generation: 1, authenticity_token: @token })
    check(@http.response.status == 303 && @learner.reload.dino_color == "green", "stara forma za izbor odbijena")
    form("/shop/purchases", item_id: "dino_tricera")
    check(@learner.reload.xp_balance == 500, "kupovina bez generacije odbijena")
    purchase("dino_tricera", generation: 2)
    check(@learner.reload.xp_balance == 260 && @learner.shop_purchases.count == 1, "nova generacija kupuje normalno")
    get("/shop")
    get("/progress")
    get("/alphabet")
    get("/battles/#{battle.id}")
    puts "FINAL_FIXTURE lifetime=#{@learner.xp} spent=#{@learner.xp_spent} wallet=#{@learner.xp_balance} generation=#{@learner.shop_generation} purchases=#{@learner.shop_purchases.count}"
  end
end

puts "PRODUCTION PROVERA V5 — sekvencijalna prodavnica i roditeljski reset"
puts "Baza: storage/v5-production.sqlite3; sve migracije 000100–000600 na praznoj bazi."
puts "Bez HTTP servera/browsera; Rails/Rack integration sa ukljucenom CSRF zastitom."
ProductionShopV5Check.new.run
protected_paths.each do |path|
  same = Digest::SHA256.file(path).hexdigest == before.fetch(path.to_s)
  puts "#{same ? 'PASS' : 'INFO'} #{path.basename}: SHA-256 #{same ? 'nepromenjen' : 'promenjen tokom rada drugog procesa'}; nije otvarana SQLite veza u ovoj proveri."
end
puts "PRODUCTION SMOKE: PASS"
puts "OGRANICENJA: sinteticki XP i rezultati crtanja; bez stvarnog browsera/dodira, HTTPS-a, reverse proxy-ja, Dockera ili javnog hostinga."
