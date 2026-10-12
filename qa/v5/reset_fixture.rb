# Disposable browser fixture only; never reset the family's learning record.
raise 'Use the v5 browser fixture' unless ENV['DATABASE_PATH'] == 'storage/v5-browser.sqlite3'
learner = Learner.current
before = { missions: learner.completed_missions, attempts: learner.attempts.count,
  letters: learner.letter_progresses.count, parts: learner.part_unlocks.count,
  sessions: learner.practice_sessions.count, battles: learner.battles.count }
ShopReset.reset!(learner, confirmation: '1', reset_word: 'RESET', generation: learner.shop_generation)
learner.reload
after = { missions: learner.completed_missions, attempts: learner.attempts.count,
  letters: learner.letter_progresses.count, parts: learner.part_unlocks.count,
  sessions: learner.practice_sessions.count, battles: learner.battles.count }
raise 'Learning changed' unless before == after
raise 'Shop not reset' unless learner.xp.zero? && learner.xp_spent.zero? && learner.shop_purchases.empty? && learner.level == 1
puts({ before_learning: before, after_learning: after, xp: learner.xp, wallet: learner.xp_balance,
  generation: learner.shop_generation, dino: learner.selected_dino, color: learner.dino_color,
  theme: learner.selected_theme, effect: learner.selected_effect }.to_json)
