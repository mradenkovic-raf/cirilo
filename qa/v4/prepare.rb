# Isolated visual fixtures; never point this at the family's database.
raise "Use DATABASE_PATH=storage/v4-browser.sqlite3" unless ENV["DATABASE_PATH"] == "storage/v4-browser.sqlite3"
learner = Learner.current
metrics = { coverage: 0.95, precision: 0.95, points: 40, drawnLength: 250, guideLength: 230 }
until learner.reload.completed_missions >= ENV.fetch("QA_MISSIONS", "1").to_i
  mission = PracticePlanner.start!(learner)
  until mission.reload.completed?
    exercise = mission.current_exercise
    recorder = AttemptRecorder.new(mission)
    attrs = { exercise_id: exercise.fetch("id"), answer: exercise["answer"] }
    case exercise.fetch("kind")
    when "trace"
      attrs.merge!(trace_score: 95, trace_metrics: metrics)
    when "write_word", "fill_letters"
      attrs[:letter_traces] = exercise.fetch("writing_letters").map do |letter|
        { index: letter.fetch("index"), letter: letter.fetch("target"), score: 95, metrics: metrics }
      end
    when "memory_word"
      recorder.memorize!(exercise_id: exercise.fetch("id"))
    end
    recorder.submit!(**attrs)
  end
end
puts({ fixture_only: true, missions: learner.reload.completed_missions, parts: learner.part_unlocks.count, xp: learner.xp, wallet: learner.xp_balance }.to_json)
