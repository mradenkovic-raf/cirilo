# Destructive check limited to the disposable preview database.
raise "Use DATABASE_PATH=storage/v7-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v7-browser.sqlite3"
raise "Wrong connection" unless ActiveRecord::Base.connection_db_config.database == "storage/v7-browser.sqlite3"
learner = Learner.current
puts({ fixture_only: true, before: learner.attributes.slice("xp", "xp_spent", "completed_missions") }.to_json)
FullReset.reset!(learner, confirmation: "1", reset_word: "RESET",
  shop_generation: learner.shop_generation, dinosaur_generation: learner.dinosaur_generation)
puts({ fixture_only: true, after: learner.reload.attributes.slice("xp", "xp_spent", "completed_missions"),
  friends: AdventureMap.new(learner).rescued_count,
  remaining: %i[practice_sessions attempts battles part_unlocks shop_purchases letter_confusions letter_progresses].to_h { |name| [name, learner.public_send(name).count] }
}.to_json)
