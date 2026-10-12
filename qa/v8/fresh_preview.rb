raise 'Preview database only' unless ENV['DATABASE_PATH'] == 'storage/v8-browser.sqlite3'
learner = Learner.current
FullReset.reset!(learner, confirmation: '1', reset_word: 'RESET', shop_generation: learner.shop_generation, dinosaur_generation: learner.dinosaur_generation)
puts({fixture_only: true, xp: learner.xp, missions: learner.completed_missions, friends: AdventureMap.new(learner).rescued_count}.to_json)
