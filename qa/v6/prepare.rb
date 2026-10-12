# Synthetic progress for local browser checks. Never use the family database.
raise "Use DATABASE_PATH=storage/v6-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v6-browser.sqlite3"
require_relative "../../test/services/exercise_helpers"
include ExerciseHelpers

learner = Learner.current
case ENV.fetch("QA_ACTION", "prepare")
when "start"
  mission = PracticePlanner.start!(learner)
  puts({ fixture_only: true, mission_url: "/practice_sessions/#{mission.id}" }.to_json)
when "prepare"
  until learner.reload.completed_missions >= 12
    complete_practice_session(PracticePlanner.start!(learner))
  end
  finished = learner.practice_sessions.where(status: "completed").order(:id).last
  battle = BattleArena.start!(learner, finished)
  puts({ fixture_only: true, battle_url: "/battles/#{battle.id}" }.to_json)
when "story"
  mission = PracticePlanner.start!(learner)
  until mission.reload.completed? || mission.current_exercise.fetch("kind") == "story_action"
    solve_current_exercise(mission)
  end
  raise "No story task in this mission" if mission.completed?
  puts({ fixture_only: true, mission_url: "/practice_sessions/#{mission.id}",
    kind: mission.current_exercise.fetch("kind") }.to_json)
when "finish"
  complete_practice_session(learner.active_session) if learner.active_session
when "confusion"
  mission = PracticePlanner.start!(learner)
  until mission.reload.completed? || mission.current_exercise.fetch("kind") == "fill_letters"
    solve_current_exercise(mission)
  end
  raise "No fill task available" if mission.completed?
  exercise = mission.current_exercise
  attrs = correct_attributes(exercise)
  target = exercise.fetch("writing_letters").first
  wrong = target.fetch("options").find { |option| option.fetch("target") != target.fetch("target") }
  attrs.fetch(:letter_traces).first[:letter] = wrong.fetch("target")
  AttemptRecorder.new(mission).submit!(**attrs)
  puts({ fixture_only: true, observed_pair: [target.fetch("target"), wrong.fetch("target")],
    observations: LetterConfusion.for_learner(learner).count }.to_json)
else
  raise "Unknown QA action"
end
puts({ fixture_only: true, missions: learner.reload.completed_missions,
  parts: learner.part_unlocks.count, xp: learner.xp, wallet: learner.xp_balance }.to_json)
