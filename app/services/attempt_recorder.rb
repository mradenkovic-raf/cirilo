class AttemptRecorder
  class InvalidSubmission < StandardError; end
  class StaleExercise < StandardError; end

  TASK_XP = 10
  MISSION_BONUS = 25
  MAX_RECOVERIES = 3
  WRITING_KINDS = %w[write_word fill_letters].freeze

  def initialize(practice_session)
    @session = practice_session
    @learner = practice_session.learner
  end

  def submit!(exercise_id:, answer: nil, trace_score: nil, trace_metrics: {}, letter_traces: nil, assisted: false)
    validate_exercise_id!(exercise_id)
    @learner.with_lock do
      @session.reload
      previous = @session.attempts.find_by(exercise_id: exercise_id, correct: true)
      next response(previous, duplicate: true) if previous
      exercise = current_exercise!(exercise_id)
      score, metrics = nil, {}
      if exercise.fetch("kind") == "trace"
        answer = nil
        score, metrics = validated_trace(trace_score, trace_metrics)
        correct = trace_passes?(score, metrics)
      elsif WRITING_KINDS.include?(exercise.fetch("kind"))
        score, metrics = validated_letter_traces(exercise, letter_traces)
        answer = metrics.fetch("letters").map { |item| item.fetch("letter") }.join
        correct = metrics.fetch("feedback").all? { |item| item.fetch("correct") }
      else
        if exercise.fetch("kind") == "memory_word" && !exercise["memory_hidden"]
          raise InvalidSubmission, "Прво запамти реч и притисни „Запамтио сам”."
        end
        answer = validated_answer(exercise, answer)
        correct = answer == exercise.fetch("answer")
      end

      first_try = !@session.attempts.where(exercise_id: exercise_id, correct: false).exists?
      recovery = exercise["recovery_of"].present?
      recall_eligible = first_try && assisted == false && PracticePlanner::COMPATIBLE_VERSIONS.include?(exercise["version"]) &&
        !exercise["review_only"] && !exercise["help_used"]
      earned = correct && !recovery ? TASK_XP : 0
      attempt = @session.attempts.create!(
        learner: @learner, exercise_id: exercise_id, letter_id: exercise.fetch("letter_id"),
        kind: exercise.fetch("kind"), answer: answer, correct: correct,
        score: score, trace_metrics: metrics, xp_earned: earned
      )
      progress = @learner.letter_progresses.find_by!(letter_id: exercise.fetch("letter_id"))
      if !%w[story_action word_pairs].include?(exercise.fetch("kind")) && (correct || (first_try && !recovery))
        progress.record_practice!(correct: correct, kind: exercise.fetch("kind"), recall_eligible: recall_eligible)
      end
      ConfusionTracker.record!(learner: @learner, session: @session, exercise: exercise,
        answer: answer, metrics: metrics, correct: correct, eligible: recall_eligible)

      if correct
        @session.cursor += 1
        @session.earned_xp += earned
        @learner.xp += earned
        complete_mission! if @session.cursor >= @session.total_exercises
        @session.save!
        @learner.save!
      elsif first_try && !recovery
        insert_recovery!(exercise)
      end
      response(attempt)
    end
  end

  def memorize!(exercise_id:)
    validate_exercise_id!(exercise_id)
    @learner.with_lock do
      @session.reload
      exercise = current_exercise!(exercise_id)
      unless exercise.fetch("kind") == "memory_word"
        raise InvalidSubmission, "Овај задатак нема корак за памћење речи."
      end
      unless exercise["memory_hidden"]
        updated = @session.exercises.deep_dup
        updated[@session.cursor]["memory_hidden"] = true
        @session.update!(exercises: updated)
      end
      { success: true, memory_hidden: true, total: @session.total_exercises,
        cursor: @session.cursor, progress: @session.progress_percent }
    end
  end

  private

  def validate_exercise_id!(exercise_id)
    raise InvalidSubmission, "Недостаје задатак." unless exercise_id.is_a?(String) && exercise_id.present?
  end

  def current_exercise!(exercise_id)
    exercise = @session.current_exercise
    unless exercise && exercise.fetch("id") == exercise_id
      raise StaleExercise, "Овај задатак је већ промењен. Настави текућу мисију."
    end
    exercise
  end

  def validated_answer(exercise, raw_answer)
    unless raw_answer.is_a?(String) && raw_answer.length.between?(1, 12)
      raise InvalidSubmission, "Састави реч или изабери један понуђени одговор."
    end
    answer = raw_answer.unicode_normalize(:nfc).strip
    answer = answer.upcase if exercise["version"].to_i >= 2
    if %w[build_word memory_word].include?(exercise.fetch("kind"))
      available = exercise.fetch("tiles").map(&:upcase).tally
      used = answer.chars.tally
      valid = answer.length == exercise.fetch("answer").length &&
        used.all? { |char, count| available.fetch(char, 0) >= count }
      raise InvalidSubmission, "Попуни сва места понуђеним словима. Сваку плочицу употреби само једном." unless valid
    elsif exercise.fetch("kind") == "repair_word"
      broken = exercise.fetch("broken_word")
      changed = broken.chars.zip(answer.chars).filter_map { |before, after| after unless before == after }
      unless answer.length == broken.length && changed.length == 1 && exercise.fetch("repair_options").include?(changed.first)
        raise InvalidSubmission, "Промени једно слово у речи неким од понуђених слова."
      end
    elsif exercise.fetch("kind") == "word_pairs"
      allowed = exercise.fetch("pair_pictures").map { |item| item.fetch("id") }
      selected = answer.split(",", -1)
      unless selected.length == exercise.fetch("pair_words").length && selected.sort == allowed.sort
        raise InvalidSubmission, "Споји све речи са сликама. Сваку слику употреби само једном."
      end
    elsif !exercise.fetch("options").include?(answer)
      raise InvalidSubmission, "Изабери један од понуђених одговора."
    end
    answer
  end

  def validated_letter_traces(exercise, raw_traces)
    expected = exercise.fetch("writing_letters")
    unless raw_traces.is_a?(Array) && raw_traces.length == expected.length && raw_traces.all? { |item| item.is_a?(Hash) }
      raise InvalidSubmission, "Напиши свако тражено слово пре него што потврдиш реч."
    end
    submitted = raw_traces.map(&:stringify_keys)
    indices = submitted.map { |item| item["index"] }
    unless indices.all? { |index| index.is_a?(Integer) } && indices.sort == expected.map { |item| item.fetch("index") }.sort
      raise InvalidSubmission, "Свако тражено место треба да има тачно једно написано слово."
    end
    results = expected.map do |target|
      data = submitted.find { |item| item.fetch("index") == target.fetch("index") }
      raw_letter = data["letter"]
      unless raw_letter.is_a?(String) && raw_letter.length.between?(1, 2)
        raise InvalidSubmission, "Изабери слово за свако тражено место."
      end
      letter = raw_letter.unicode_normalize(:nfc).upcase
      allowed = target.fetch("options", [target]).map { |option| option.fetch("target").upcase }
      raise InvalidSubmission, "Изабери једно од слова понуђених за то место." unless allowed.include?(letter)
      score, metrics = validated_trace(data["score"], data["metrics"])
      { "index" => target.fetch("index"), "letter" => letter, "score" => score, "metrics" => metrics,
        "correct" => letter == target.fetch("target").upcase && trace_passes?(score, metrics) }
    end
    feedback = results.map { |item| item.slice("index", "score", "correct") }
    [results.map { |item| item.fetch("score") }.min, { "letters" => results, "feedback" => feedback }]
  end

  def insert_recovery!(exercise)
    return if !PracticePlanner::COMPATIBLE_VERSIONS.include?(exercise["version"]) || exercise["review_only"]
    return if @session.exercises.count { |item| item["recovery_of"] } >= MAX_RECOVERIES
    return if @session.exercises.any? { |item| item["recovery_of"] == exercise.fetch("id") }
    completed = @session.exercises.first(@session.cursor).select do |item|
      PracticePlanner::COMPATIBLE_VERSIONS.include?(item["version"]) && !item["recovery_of"]
    end
    source = if exercise["version"].to_i >= 6
      completed.reverse.find { |item| PracticePlanner::READING_KINDS.include?(item["kind"]) } ||
        PracticePlanner.reading_review(letter_id: exercise.fetch("letter_id"),
          letter_case: exercise.fetch("case", "upper"), variation: @learner.completed_missions,
          letter_ids: @session.school_mode? ? @session.school_letter_ids : nil)
    else
      completed.reverse.find { |item| item["kind"] == "trace" } || completed.last
    end
    unless source
      letter = Curriculum.find(exercise.fetch("letter_id"))
      letter_case = exercise.fetch("case", "upper")
      source = { "version" => exercise.fetch("version"), "kind" => "trace", "letter_id" => letter.fetch("id"),
        "case" => letter_case, "display_case" => letter_case, "target" => letter.fetch(letter_case),
        "answer" => letter.fetch(letter_case), "prompt" => "Још једном напиши слово #{letter.fetch(letter_case)}." }
    end
    recovery = recovery_copy(source).merge("recovery_of" => exercise.fetch("id"))
    updated = @session.exercises.deep_dup
    updated.insert(@session.cursor, recovery)
    @session.update!(exercises: updated)
  end

  def recovery_copy(exercise)
    copy = exercise.deep_dup.merge("id" => SecureRandom.uuid,
      "review_only" => true, "extra_review" => true, "zero_xp" => true)
    copy.delete("help_used")
    copy.delete("retry_of")
    copy["memory_hidden"] = false if copy["kind"] == "memory_word"
    if copy["tiles"]
      copy["tiles"] = @session.school_mode? ? rearrange(copy.fetch("tiles")) : WordBank.tiles(copy.fetch("word"))
      copy["tiles"].rotate! if copy["tiles"] == exercise["tiles"]
    end
    if copy["choices"]
      copy["choices"] = rearrange(copy.fetch("choices"))
      copy["options"] = copy.fetch("choices").map { |choice| choice.fetch("value") }
    elsif copy["options"]
      copy["options"] = rearrange(copy.fetch("options"))
    end
    copy.fetch("writing_letters", []).each do |letter|
      letter["options"] = rearrange(letter["options"]) if letter["options"]
    end
    copy["repair_options"] = rearrange(copy["repair_options"]) if copy["repair_options"]
    if copy["pair_pictures"]
      pictures = rearrange(copy["pair_pictures"])
      while pictures == exercise["pair_pictures"] || pictures.map { |item| item.fetch("id") } == copy.fetch("answer").split(",")
        pictures.rotate!
      end
      copy["pair_pictures"] = pictures
    end
    copy
  end

  def rearrange(items)
    result = items.shuffle
    result.rotate! if result == items && items.length > 1
    result
  end

  def validated_trace(raw_score, raw_metrics)
    raise InvalidSubmission, "Покушај поново да нацрташ слово." unless raw_metrics.is_a?(Hash)
    values = raw_metrics.stringify_keys
    score = finite_number(raw_score, 0..100)
    metrics = {
      "coverage" => finite_number(values["coverage"], 0..1),
      "precision" => finite_number(values["precision"], 0..1),
      "points" => finite_number(values["points"], 0..100_000),
      "drawnLength" => finite_number(values["drawnLength"], 0..1_000_000),
      "guideLength" => finite_number(values["guideLength"], 0..1_000_000)
    }
    unless metrics["points"].to_i == metrics["points"] && metrics["guideLength"].positive?
      raise InvalidSubmission, "Покушај поново да нацрташ слово."
    end
    metrics["points"] = metrics["points"].to_i
    # The browser supplies a geometry heuristic, not handwriting recognition.
    score = 0 if metrics["points"] < 2 || metrics["drawnLength"] < 15
    [score.round, metrics]
  end

  def trace_passes?(score, metrics)
    score >= 65 && metrics.fetch("coverage") >= 0.55 && metrics.fetch("drawnLength") >= 15
  end

  def finite_number(value, range)
    number = Float(value)
    raise InvalidSubmission unless number.finite? && range.cover?(number)
    number
  rescue ArgumentError, TypeError, InvalidSubmission
    raise InvalidSubmission, "Подаци о цртању нису потпуни. Покушај поново."
  end

  def complete_mission!
    @session.status = "completed"
    @session.completed_at = Time.current
    @session.earned_xp += MISSION_BONUS
    @learner.xp += MISSION_BONUS
    @learner.completed_missions += 1
    reward_position = @learner.part_unlocks.count + 1
    part = Curriculum.part_at(reward_position)
    @learner.part_unlocks.create!(practice_session: @session,
      part_key: part.fetch("id"), position: reward_position)
  end

  def response(attempt, duplicate: false)
    completed = @session.completed?
    reward = completed ? @session.part_unlock&.part : nil
    awarded = duplicate ? 0 : attempt.xp_earned + (completed && attempt.correct? ? MISSION_BONUS : 0)
    exercise = @session.exercises.find { |item| item["id"] == attempt.exercise_id }
    recovery_required = !attempt.correct? && @session.current_exercise&.fetch("recovery_of", nil) == attempt.exercise_id
    bank = @session.school_mode? ? SchoolWordBank : WordBank
    entry = attempt.correct? && exercise && exercise["word"] && bank.find(exercise["word"])
    entry = nil if entry && entry["picture"] == false
    meaning = entry && { word: entry.fetch("word"), emoji: entry.fetch("emoji"),
      sentence: @session.school_mode? ? "" : entry.fetch("sentence").sub("▢", entry.fetch("word").downcase) }
    meaning[:image_url] = SchoolWordBank.image_url(entry) if meaning && entry["image"]
    {
      success: true, correct: attempt.correct?, duplicate: duplicate, recovery_required: recovery_required,
      score: attempt.score, letter_feedback: attempt.trace_metrics["feedback"],
      xp_earned: awarded, total_xp: @learner.xp, xp_balance: @learner.xp_balance, meaning: meaning || nil,
      completed: completed, cursor: @session.cursor, total: @session.total_exercises,
      drive_checkpoint: @session.drive_checkpoint_state,
      progress: @session.progress_percent, unlocked_part: reward,
      next_url: "/practice_sessions/#{@session.id}",
      feedback: feedback_for(attempt, completed, recovery_required)
    }
  end

  def feedback_for(attempt, completed, recovery_required)
    return "Мисија завршена! Твој дино те чека у радионици." if completed
    return "Кратко понови један задатак, па се враћамо на овај." if recovery_required
    return "Понављање је готово. Сада се враћамо на твој задатак." if attempt.correct? && attempt.xp_earned.zero?
    return ["Браво! Успео си!", "Одлично! Идемо даље!", "То је то! Дино се радује!"][@session.cursor % 3] if attempt.correct?
    "Покушај поново. Полако, можеш ти то."
  end
end
