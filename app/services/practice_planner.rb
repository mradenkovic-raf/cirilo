class PracticePlanner
  VERSION = 7
  COMPATIBLE_VERSIONS = [3, 4, 5, 6, 7].freeze
  MISSION_LENGTH = 12
  READING_KINDS = %w[read_word picture_word build_word repair_word word_pairs sentence memory_word story_action].freeze
  # Ten reading/letter tasks and two separated handwriting breaks. Every focus
  # letter returns four times; handwriting is no longer required for each one.
  MISSION_PLAN = [
    ["read_word", 0], ["story_action", 1], ["build_word", 0], ["trace", 0],
    ["repair_word", 1], ["word_pairs", 2], ["sentence", 2], ["memory_word", 1],
    ["read_word", 2], ["write_word", 1], ["story_action", 2], ["picture_word", 0]
  ].freeze
  VARIETY_ROTATION = {
    "write_word" => %w[write_word fill_letters]
  }.freeze

  class << self
    def start!(learner)
      learner.with_lock do
        active = learner.active_session
        active ? upgrade_locked!(active, learner) : build_session!(learner)
      end
    end

    def upgrade!(session)
      session.learner.with_lock do
        upgrade_locked!(session.reload, session.learner)
      end
    end

    def next_letters(learner)
      return SchoolPracticePlanner.next_letters(learner) if learner.school_mode?

      full_next_letters(learner)
    end

    def full_next_letters(learner)
      known = learner.letter_progresses.index_by(&:letter_id)
      return Curriculum.ordered_letters.first(3) if known.empty?

      candidates = known.values.sort_by do |progress|
        [progress.due? ? 0 : 1, progress.review_level,
          progress.next_review_at || Time.at(0), progress.last_practiced_at || Time.at(0)]
      end
      new_letter = Curriculum.ordered_letters.find { |letter| !known.key?(letter["id"]) }
      selected = candidates.first(new_letter ? 2 : 3).filter_map { |progress| Curriculum.find(progress.letter_id) }
      selected << new_letter if new_letter
      confusion = LetterConfusion.for_learner(learner).active.prioritized.first
      return selected unless confusion

      # A real substitution gets priority without introducing a second new focus
      # letter merely because its tile appeared in an earlier word.
      candidates = [confusion.expected_letter, confusion.chosen_letter] + selected +
        known.keys.filter_map { |id| Curriculum.find(id) }
      adapted = []
      candidates.uniq { |letter| letter.fetch("id") }.each do |letter|
        next if !known.key?(letter.fetch("id")) && adapted.any? { |item| !known.key?(item.fetch("id")) }
        adapted << letter
        break if adapted.length == 3
      end
      adapted
    end

    def reading_review(letter_id:, letter_case:, variation:, letter_ids: nil)
      if letter_ids
        return SchoolPracticePlanner.reading_review(letter_id: letter_id, letter_case: letter_case,
          variation: variation, letter_ids: letter_ids)
      end
      letter = Curriculum.find(letter_id)
      entry = WordBank.for_letter(letter, variation: variation)
      exercise(letter, entry, "read_word", letter_case)
    end

    private

    def build_session!(learner)
      focus = next_letters(learner)
      ids = learner.school_mode? ? SchoolCurriculum.canonical_ids(learner.school_letter_ids) : []
      exercises = if learner.school_mode?
        variation = learner.practice_sessions.where(status: "completed", learning_mode: "school")
          .where("school_letter_ids = ?", ids.to_json).count
        SchoolPracticePlanner.exercises(learner, letter_ids: ids, variation: variation)
      else
        mission_exercises(focus, learner)
      end
      (focus.map { |letter| letter.fetch("id") } + exercises.map { |exercise| exercise.fetch("letter_id") }).uniq.each do |id|
        learner.letter_progresses.find_or_create_by!(letter_id: id)
      end
      learner.practice_sessions.create!(exercises: exercises, learning_mode: learner.learning_mode, school_letter_ids: ids,
        focus_letters: focus.map { |letter| letter.fetch("id") })
    end

    def upgrade_locked!(session, learner)
      return session if session.completed?
      remaining = session.exercises.drop(session.cursor)
      # Preserve compatible saved questions and their original mode/scope.
      # New parent settings only apply when creating the following mission.
      return session if remaining.any? && remaining.all? { |exercise| COMPATIBLE_VERSIONS.include?(exercise["version"]) }

      focus = session.focus_letters.filter_map { |id| Curriculum.find(id) }
      focus = (focus + (session.school_mode? ? SchoolCurriculum.letters_for(session.school_letter_ids) : full_next_letters(learner))).uniq { |letter| letter.fetch("id") }.first(3)
      focus.each { |letter| learner.letter_progresses.find_or_create_by!(letter_id: letter.fetch("id")) }
      # Completed exercise IDs, attempts, cursor and earned XP stay untouched.
      # A page left open before this change receives a normal stale-task reply.
      completed = session.exercises.first(session.cursor)
      fresh = if session.school_mode?
        SchoolPracticePlanner.exercises(learner, letter_ids: session.school_letter_ids, variation: learner.completed_missions)
      else
        mission_exercises(focus, learner)
      end
      fresh.each { |exercise| learner.letter_progresses.find_or_create_by!(letter_id: exercise.fetch("letter_id")) }
      replacement = fresh.drop(session.cursor)
      replacement = [fresh.first] if replacement.empty?
      session.update!(exercises: completed + replacement,
        focus_letters: focus.map { |letter| letter.fetch("id") })
      session
    end

    def mission_exercises(focus, learner)
      variation = learner.completed_missions
      chosen_words = []
      entries = focus.map do |letter|
        entry = WordBank.for_letter(letter, variation: variation, excluding: chosen_words)
        chosen_words << entry.fetch("word")
        entry
      end
      story_index = 0
      MISSION_PLAN.each_with_index.map do |(kind, letter_index), index|
        rotation = VARIETY_ROTATION[kind]
        kind = rotation ? rotation.fetch(variation % rotation.length) : kind
        letter_case = (letter_index + variation + index).even? ? "upper" : "lower"
        task = exercise(focus.fetch(letter_index), entries.fetch(letter_index), kind, letter_case)
        if kind == "story_action"
          task.merge!(story_index.zero? ? StoryBank.position_exercise(variation: variation) : StoryBank.exercise(variation: variation))
          story_index += 1
        end
        if %w[picture_word word_pairs].include?(kind)
          task.merge!(VarietyBank.public_send(kind, entries.fetch(letter_index), variation: variation))
        elsif kind == "repair_word"
          task.merge!(VarietyBank.repair_word(entries.fetch(letter_index), letter: focus.fetch(letter_index), variation: variation))
        end
        adapt_confusions!(task, learner)
      end
    end

    def exercise(letter, entry, kind, letter_case)
      common = {
        "id" => SecureRandom.uuid, "version" => VERSION, "kind" => kind,
        "letter_id" => letter.fetch("id"), "case" => letter_case,
        "display_case" => letter_case, "review_only" => false
      }
      word = entry.fetch("word")
      case kind
      when "trace"
        case_name = letter_case == "upper" ? "велико" : "мало"
        common.merge("target" => letter.fetch(letter_case), "answer" => letter.fetch(letter_case),
          "prompt" => "Напиши #{case_name} слово #{letter.fetch('upper')}.")
      when "build_word", "memory_word"
        common.merge("word" => word, "answer" => word, "tiles" => WordBank.tiles(word),
          "memory_hidden" => false,
          "emoji" => kind == "build_word" ? entry.fetch("emoji") : nil,
          "image" => kind == "build_word" ? entry["image"] : nil,
          "prompt" => kind == "build_word" ? "Шта је на слици? Састави реч." : "Запамти реч, па је састави без гледања.")
      when "write_word", "fill_letters"
        indices = kind == "write_word" ? (0...word.length).to_a : missing_indices(word, letter)
        letters = word.chars.each_with_index.filter_map do |char, index|
          next unless indices.include?(index)
          source = Curriculum.letters.find { |item| item.fetch("upper") == char }
          writing = { "index" => index, "letter_id" => source.fetch("id"),
            "target" => source.fetch(letter_case), "paths" => source.fetch("strokes").fetch(letter_case) }
          writing["options"] = writing_options(source, letter_case) if kind == "fill_letters"
          writing
        end
        pattern = word.chars.each_with_index.map do |char, index|
          indices.include?(index) ? "_" : (letter_case == "lower" ? char.downcase : char)
        end.join
        common.merge("word" => word, "answer" => word, "emoji" => entry.fetch("emoji"),
          "image" => entry["image"],
          "word_pattern" => pattern, "writing_letters" => letters,
          "prompt" => kind == "write_word" ? "Напиши целу реч, слово по слово." : "Изабери и напиши слова која недостају.")
      when "read_word"
        choices = WordBank.picture_choices(entry)
        common.merge("word" => word, "answer" => word, "choices" => choices,
          "options" => choices.map { |choice| choice.fetch("value") },
          "prompt" => "Прочитај реч и пронађи њену слику.")
      when "sentence"
        common.merge("answer" => word, "word" => word,
          "sentence_pattern" => entry.fetch("sentence"),
          "options" => ([word] + entry.fetch("sentence_options")).shuffle,
          "prompt" => "Прочитај реченицу. Која реч недостаје?")
      when "story_action", "picture_word", "repair_word", "word_pairs"
        common
      end
    end

    def missing_indices(word, letter)
      first = word.index(letter.fetch("upper")) || 0
      count = [2, word.length / 2].min
      rest = (0...word.length).to_a.reject { |index| index == first }
      [first, *rest.sort_by { |index| -(index - first).abs }.first(count - 1)].sort
    end

    def writing_options(letter, letter_case)
      others = Curriculum.letters.reject { |item| item.fetch("id") == letter.fetch("id") }.sample(3)
      ([letter] + others).shuffle.map do |item|
        { "letter_id" => item.fetch("id"), "target" => item.fetch(letter_case),
          "paths" => item.fetch("strokes").fetch(letter_case) }
      end
    end

    def adapt_confusions!(task, learner)
      pairs = LetterConfusion.for_learner(learner).active.prioritized.to_a
      if task.fetch("kind") == "trace"
        pair = pairs.find { |item| item.expected_letter_id == task.fetch("letter_id") }
        task["contrast_letters"] = [pair.expected_letter, pair.chosen_letter].map { |letter| letter.fetch(task.fetch("case")) } if pair
      elsif %w[build_word memory_word].include?(task.fetch("kind"))
        pair = pairs.find { |item| task.fetch("word").include?(item.expected_letter.fetch("upper")) }
        if pair
          task["tiles"] = WordBank.tiles(task.fetch("word"), distractors: [pair.chosen_letter.fetch("upper")])
          task["confusion_checks"] = [{ "expected" => pair.expected_letter_id, "chosen" => pair.chosen_letter_id }]
        end
      elsif task.fetch("kind") == "fill_letters"
        task.fetch("writing_letters").each do |writing|
          pair = pairs.find { |item| item.expected_letter_id == writing.fetch("letter_id") }
          next unless pair
          chosen = pair.chosen_letter
          others = writing.fetch("options").reject { |option| [writing.fetch("letter_id"), chosen.fetch("id")].include?(option.fetch("letter_id")) }
          target = writing.slice("letter_id", "target", "paths")
          alternate = { "letter_id" => chosen.fetch("id"), "target" => chosen.fetch(task.fetch("case")), "paths" => chosen.fetch("strokes").fetch(task.fetch("case")) }
          writing["options"] = ([target, alternate] + others.first(2)).shuffle
        end
      end
      task
    end
  end
end
