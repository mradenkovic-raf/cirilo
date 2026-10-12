# Synthetic progress for the local preview only. Never use the family database.
raise "Use DATABASE_PATH=storage/v8-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v8-browser.sqlite3"
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers

learner = Learner.current
until learner.reload.completed_missions >= 16
  complete_practice_session(PracticePlanner.start!(learner))
end
mission = learner.practice_sessions.where(status: "completed").order(:id).last
BattleArena.start!(learner, mission)
ShopService.new(learner).purchase!(item_id: "theme_space", generation: learner.shop_generation)
PracticePlanner.start!(learner)
puts({ fixture_only: true, missions: learner.reload.completed_missions,
  parts: learner.part_unlocks.count, friends: AdventureMap.new(learner).rescued_count,
  xp: learner.xp, wallet: learner.xp_balance }.to_json)
