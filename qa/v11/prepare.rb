raise "Preview database only" unless ENV["DATABASE_PATH"] == "storage/v11-browser.sqlite3"
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers

learner = Learner.current
case ARGV.fetch(0)
when "setup"
  raise "Use a fresh preview database" if learner.practice_sessions.exists?
  learner.update!(selected_dino: "stego", dino_color: "blue")
  battles = 2.times.map do |i|
    mission = complete_practice_session(PracticePlanner.start!(learner))
    battle = BattleArena.start!(learner, mission)
    battle.update!(i.zero? ? { enemy_hp: 1, next_enemy_move: "feint" } : { player_hp: 1, next_enemy_move: "guard" })
    battle.id
  end
  mission = PracticePlanner.start!(learner)
  exercises = mission.exercises
  exercises[0] = PracticePlanner.send(:exercise, Curriculum.find("l"), WordBank.find("ЛИСИЦА"), "write_word", "upper")
  exercises[1] = exercises[2].deep_dup
  exercises[2] = planned_exercise("trace")
  mission.update!(exercises: exercises)
  learner.letter_progresses.find_or_create_by!(letter_id: "l")
  puts({ writing: "/practice_sessions/#{mission.id}", victory: "/battles/#{battles[0]}", defeat: "/battles/#{battles[1]}" }.to_json)
when "advance_word"
  session = learner.active_session
  raise "Expected initial writing fixture" unless session.cursor.zero? && session.current_exercise.fetch("kind") == "write_word"
  learner.letter_progresses.find_or_create_by!(letter_id: "l")
  solve_current_exercise(session)
  puts({ cursor: session.reload.cursor, current: session.current_exercise.slice("kind", "word", "answer") }.to_json)
when "near_end"
  session = learner.active_session
  solve_current_exercise(session) until session.reload.cursor == session.total_exercises - 1
  exercise = PracticePlanner.send(:exercise, Curriculum.find("l"), WordBank.find("ЛИСИЦА"), "picture_word", "upper")
  exercise.merge!(VarietyBank.picture_word(WordBank.find("ЛИСИЦА"), variation: 0))
  session.update!(exercises: session.exercises[0...-1] + [exercise])
  puts({ cursor: session.cursor, total: session.total_exercises, answer: exercise["answer"] }.to_json)
end
