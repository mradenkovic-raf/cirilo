raise 'Preview database only' unless ENV['DATABASE_PATH'] == 'storage/v8-browser.sqlite3'
require_relative '../../test/services/exercise_helpers'
include ExerciseHelpers
session = Learner.current.active_session
while !session.reload.completed? && session.current_exercise['kind'] != ARGV.fetch(0)
  solve_current_exercise(session)
end
puts({session: session.id, completed: session.completed?, kind: session.current_exercise&.fetch('kind',nil), cursor: session.cursor}.to_json)
