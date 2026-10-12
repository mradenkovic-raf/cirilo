# Synthetic preview only: never change the child's actual progress.
raise "Use DATABASE_PATH=storage/v9-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v9-browser.sqlite3"
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers

learner = Learner.current
session = PracticePlanner.start!(learner)
if ARGV.first == "recover"
  raise "Expected a recovery task" unless session.current_exercise["recovery_of"]
  solve_current_exercise(session)
else
  kind = ARGV.first || "picture_word"
  index = session.exercises.index { |item| item["kind"] == kind && !item["review_only"] }
  raise "No #{kind} in this preview mission" unless index
  session.update!(cursor: index)
end
puts({ fixture_only: true, path: "/practice_sessions/#{session.id}", kind: session.reload.current_exercise["kind"],
  xp: learner.reload.xp }.to_json)
