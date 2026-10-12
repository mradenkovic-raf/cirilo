raise "Preview database only" unless ENV["DATABASE_PATH"] == "storage/v10-browser.sqlite3"
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers
learner = Learner.current
egg = EggCompanion.new(learner)
target = Integer(ARGV.fetch(0))
raise "Choose egg first; stage 0–3 only" unless egg.chosen? && target.between?(0, 3)
until learner.reload.completed_missions >= egg.state.fetch("started_missions") + target
  complete_practice_session(PracticePlanner.start!(learner))
end
puts({ stage: EggCompanion.new(learner.reload).stage, missions: learner.completed_missions }.to_json)
