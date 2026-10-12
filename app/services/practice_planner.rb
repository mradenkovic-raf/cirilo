class PracticePlanner
  VERSION = 5
  COMPATIBLE_VERSIONS = [3, 4, 5].freeze
  MISSION_LENGTH = 12
  MISSION_PLAN = [
    ["trace", 0], ["write_word", 1], ["read_word", 2], ["memory_word", 0],
    ["fill_letters", 2], ["sentence", 0], ["trace", 1], ["write_word", 2],
    ["story_action", 1], ["build_word", 2], ["fill_letters", 0], ["memory_word", 1]
  ].freeze
  VARIETY_ROTATION = {
    "read_word" => %w[picture_word read_word picture_word],
    "sentence" => %w[word_pairs word_pairs sentence],
    "build_word" => %w[repair_word build_word repair_word]
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

    private

    def build_session!(learner)
      focus = next_letters(learner)
      focus.each { |letter| learner.letter_progresses.find_or_create_by!(letter_id: letter.fetch("id")) }
      learner.practice_sessions.create!(exercises: mission_exercises(focus, learner),
        focus_letters: focus.map { |letter| letter.fetch("id") })
    end

    def upgrade_locked!(session, learner)
      return session if session.completed?
      remaining = session.exercises.drop(session.cursor)
      # V3 and V4 already have the current writing/recovery protocol. Never
      # rewrite an unfinished valid mission merely to introduce new task kinds.
      return session if remaining.any? && remaining.all? { |exercise| COMPATIBLE_VERSIONS.include?(exercise["version"]) }

      focus = session.focus_letters.filter_map { |id| Curriculum.find(id) }
      focus = (focus + next_letters(learner)).uniq { |letter| letter.fetch("id") }.first(3)
      focus.each { |letter| learner.letter_progresses.find_or_create_by!(letter_id: letter.fetch("id")) }
      # Completed exercise IDs, attempts, cursor and earned XP stay untouched.
      # A page left open before this change receives a normal stale-task reply.
      completed = session.exercises.first(session.cursor)
      fresh = mission_exercises(focus, learner)
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
      MISSION_PLAN.each_with_index.map do |(kind, letter_index), index|
        kind = VARIETY_ROTATION[kind]&.fetch(variation % 3) || kind
        letter_case = (letter_index + variation + index).even? ? "upper" : "lower"
        task = exercise(focus.fetch(letter_index), entries.fetch(letter_index), kind, letter_case)
        task.merge!(StoryBank.exercise(variation: variation)) if kind == "story_action"
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
