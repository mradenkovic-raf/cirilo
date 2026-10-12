module ExerciseHelpers
  # Build an explicit old kind so protocol tests do not depend on which mix a
  # newly generated mission happens to use this month.
  def planned_exercise(kind, letter_id: "a", version: PracticePlanner::VERSION)
    letter = Curriculum.find(letter_id)
    exercise = PracticePlanner.send(:exercise, letter, WordBank.for_letter(letter), kind, "upper")
    exercise.merge!(StoryBank.exercise(variation: 0)) if kind == "story_action"
    exercise.merge("version" => version)
  end

  def correct_attributes(exercise)
    attrs = { exercise_id: exercise.fetch("id"), answer: exercise.fetch("answer") }
    if exercise.fetch("kind") == "trace"
      attrs.merge!(trace_score: 92,
        trace_metrics: { coverage: 0.95, precision: 0.91, points: 20, drawnLength: 220, guideLength: 210 })
    elsif %w[write_word fill_letters].include?(exercise.fetch("kind"))
      attrs[:letter_traces] = exercise.fetch("writing_letters").map do |letter|
        { index: letter.fetch("index"), letter: letter.fetch("target"), score: 92,
          metrics: { coverage: 0.95, precision: 0.91, points: 20, drawnLength: 220, guideLength: 210 } }
      end
    end
    attrs
  end

  def complete_practice_session(session)
    until session.reload.completed?
      solve_current_exercise(session)
    end
    session
  end

  def solve_current_exercise(session)
    exercise = session.reload.current_exercise
    recorder = AttemptRecorder.new(session)
    recorder.memorize!(exercise_id: exercise.fetch("id")) if exercise.fetch("kind") == "memory_word"
    recorder.submit!(**correct_attributes(exercise))
  end
end
