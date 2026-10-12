class ConfusionTracker
  class << self
    # Called inside the same learner lock/transaction as the attempt. Only a
    # direct letter choice or one unambiguous substitution is evidence.
    def record!(learner:, session:, exercise:, answer:, metrics:, correct:, eligible:)
      return unless eligible
      if correct
        return unless %w[build_word memory_word].include?(exercise.fetch("kind"))
        exercise.fetch("confusion_checks", []).each do |pair|
          observation = LetterConfusion.for_learner(learner).active.find_by(
            expected_letter_id: pair.fetch("expected"), chosen_letter_id: pair.fetch("chosen"))
          next unless observation && observation.last_success_session_id != session.id
          observation.update!(independent_successes: observation.independent_successes + 1,
            last_success_session_id: session.id, last_success_at: Time.current)
        end
      else
        replacements(exercise, answer, metrics).uniq.each do |expected, chosen|
          target = Curriculum.letters.find { |letter| letter.fetch("upper") == expected }
          selected = Curriculum.letters.find { |letter| letter.fetch("upper") == chosen }
          next unless target && selected && target != selected
          observation = LetterConfusion.for_learner(learner).find_or_initialize_by(
            expected_letter_id: target.fetch("id"), chosen_letter_id: selected.fetch("id"))
          observation.observations += 1
          observation.independent_successes = 0
          observation.last_success_session_id = nil
          observation.last_success_at = nil
          observation.last_mistake_at = Time.current
          observation.save!
        end
      end
    end

    private

    def replacements(exercise, answer, metrics)
      if exercise.fetch("kind") == "fill_letters"
        exercise.fetch("writing_letters").filter_map do |target|
          selected = metrics.fetch("letters").find { |item| item.fetch("index") == target.fetch("index") }.fetch("letter")
          expected = target.fetch("target").upcase
          [expected, selected] unless expected == selected
        end
      elsif %w[build_word memory_word].include?(exercise.fetch("kind"))
        pairs = exercise.fetch("answer").chars.zip(answer.chars).reject { |expected, selected| expected == selected }
        pairs.length == 1 ? pairs : []
      else
        []
      end
    end
  end
end
