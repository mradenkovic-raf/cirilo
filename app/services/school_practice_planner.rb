class SchoolPracticePlanner
  MISSION_LENGTH = 12
  RECENT_MISSION_LIMIT = 6
  # Reading remains the main activity; two separated breaks practise handwriting.
  PLAN = %w[read_word story_action build_word trace repair_word word_pairs memory_word read_word build_word write_word story_action picture_word].freeze
  PICTURE_KINDS = %w[read_word picture_word build_word repair_word word_pairs write_word fill_letters].freeze

  class << self
    def next_letters(learner)
      letters = SchoolCurriculum.letters_for(learner.school_letter_ids)
      return letters if letters.length <= 3

      recent = letters.last(2)
      progresses = learner.letter_progresses.index_by(&:letter_id)
      reviews = (letters - recent).rotate(learner.completed_missions % (letters.length - 2))
      review = reviews.min_by do |letter|
        progress = progresses[letter.fetch("id")]
        [progress.nil? || progress.due? ? 0 : 1, progress&.review_level || 0,
          progress&.last_practiced_at || Time.at(0)]
      end
      recent + [review]
    end

    def exercises(learner, letter_ids:, variation:)
      new(learner, letter_ids: letter_ids, variation: variation).exercises
    end

    def reading_review(letter_id:, letter_case:, variation:, letter_ids:)
      planner = new(nil, letter_ids: letter_ids, variation: variation)
      planner.reading_review(letter_id: letter_id, letter_case: letter_case)
    end

    # Recovery tasks use the saved mission scope, even if a parent has changed
    # the next mission's settings in another tab.
    def tiles(word, letter_ids:, distractors: [], random: Random.new)
      alphabet = SchoolCurriculum.letters_for(letter_ids).map { |letter| letter.fetch("upper") }
      noise = ((distractors & alphabet) + alphabet.shuffle(random: random)).uniq - word.chars
      result = (word.chars + noise.first(2)).shuffle(random: random)
      if result.first(word.length).join == word && result.uniq.length > 1
        result.rotate!
        result.reverse! if result.first(word.length).join == word
      end
      result
    end
  end

  def initialize(learner, letter_ids:, variation:)
    @learner = learner
    @letter_ids = SchoolCurriculum.canonical_ids(letter_ids)
    raise ArgumentError, "Choose at least one school letter" if @letter_ids.empty?

    @letters = SchoolCurriculum.letters_for(@letter_ids)
    @alphabet = @letters.map { |letter| letter.fetch("upper") }
    @variation = variation.to_i
    @random = Random.new(@variation + @alphabet.join.codepoints.each_with_index.sum { |code, index| code * (index + 1) })
    @pool = SchoolWordBank.eligible(@letter_ids).select do |entry|
      entry.fetch("word").length <= 6 && (entry.fetch("word").chars - @alphabet).empty?
    end
    # There is no meaningful word bank for a lone consonant. The same memory
    # interaction can still practise its printed upper- and lowercase forms.
    @pool = @letters.map { |letter| { "word" => letter.fetch("upper"), "picture" => false } } if @pool.empty?
    @pool = @pool.shuffle(random: @random)
    @pictures = @pool.select { |entry| picture?(entry) }
    @used_words = Hash.new(0)
    @recent_words = recent_words
    @confusions = if learner
      LetterConfusion.for_learner(learner).active.prioritized.where(expected_letter_id: @letter_ids, chosen_letter_id: @letter_ids).to_a
    else
      []
    end
  end

  def exercises
    focus = @learner ? self.class.next_letters(@learner) : @letters.last(3)
    # Explicit scope is authoritative, including when rebuilding an old saved
    # mission after the learner's current settings have changed.
    focus = focus.select { |letter| @letter_ids.include?(letter.fetch("id")) }
    focus = @letters.last(3) if focus.empty?
    PLAN.each_with_index.map do |planned_kind, index|
      letter = focus.fetch((index + @variation) % focus.length)
      letter_case = (index + @variation).even? ? "upper" : "lower"
      if planned_kind == "trace"
        trace(letter, letter_case)
      elsif planned_kind == "story_action" && (story = school_story(index))
        story_letter = (letter if story.fetch("story_sentence").upcase.include?(letter.fetch("upper"))) ||
          focus.find { |candidate| story.fetch("story_sentence").upcase.include?(candidate.fetch("upper")) } ||
          @letters.find { |candidate| story.fetch("story_sentence").upcase.include?(candidate.fetch("upper")) }
        common(story_letter || letter, "story_action", letter_case).merge(story)
      else
        kind = planned_kind == "story_action" ? (index == 1 ? "picture_word" : "memory_word") : planned_kind
        kind = "fill_letters" if kind == "write_word" && @variation.odd?
        kind = supported_kind(kind)
        entry = select_entry(kind, letter)
        actual_letter = (letter if entry.fetch("word").include?(letter.fetch("upper"))) ||
          focus.find { |candidate| entry.fetch("word").include?(candidate.fetch("upper")) } ||
          @letters.find { |candidate| entry.fetch("word").include?(candidate.fetch("upper")) }
        task = build(entry, actual_letter, kind, letter_case, index)
        exercise_words(task).each { |word| @used_words[word] += 1 }
        task
      end
    end
  end

  def reading_review(letter_id:, letter_case:)
    letter = @letters.find { |item| item.fetch("id") == letter_id } || @letters.first
    kind = supported_kind("read_word")
    pool = kind == "read_word" ? @pictures : @pool
    entry = pool.find { |item| item.fetch("word").include?(letter.fetch("upper")) }
    unless entry
      # Never review a different, unlearned letter just because no pictured noun
      # contains the requested one yet.
      entry = @pool.find { |item| item.fetch("word").include?(letter.fetch("upper")) } ||
        { "word" => letter.fetch("upper"), "picture" => false }
      kind = "memory_word"
    end
    build(entry, letter, kind, letter_case, 0)
  end

  private

  def common(letter, kind, letter_case)
    { "id" => SecureRandom.uuid, "version" => PracticePlanner::VERSION,
      "kind" => kind, "letter_id" => letter.fetch("id"), "case" => letter_case,
      "display_case" => letter_case, "review_only" => false,
      "learning_mode" => "school", "school_letter_ids" => @letter_ids.dup }
  end

  def picture?(entry)
    entry.fetch("picture", true) && entry["emoji"].present?
  end

  def recent_words
    return {} unless @learner

    @learner.practice_sessions.where(learning_mode: "school").order(id: :desc).limit(RECENT_MISSION_LIMIT).flat_map do |session|
      # Keep familiar words in the rotation when a parent adds another letter.
      # Count missions, not retries or the main word repeated inside a pair task.
      session.exercises.select { |task| task["learning_mode"] == "school" }
        .flat_map { |task| exercise_words(task) }.uniq
    end.tally
  end

  def exercise_words(task)
    [task["word"], *task.fetch("pair_words", []).map { |pair| pair["label"] }].compact.uniq
  end

  def school_story(index)
    return unless defined?(SchoolStoryBank)

    if SchoolSpatialStoryBank.eligible(@letter_ids).any?
      # One comprehension story and one spatial reading task per mission once
      # the chosen letters permit it. New relations do not sit behind a long
      # rotation of ownership sentences.
      return SchoolStoryBank.exercise(letter_ids: @letter_ids, variation: @variation,
        family: index == 10 ? :spatial : :reading)
    end

    SchoolStoryBank.exercise(letter_ids: @letter_ids, variation: @variation * 2 + (index == 10 ? 1 : 0))
  end

  def supported_kind(kind)
    return "memory_word" if PICTURE_KINDS.include?(kind) && @pictures.empty?
    return "memory_word" if %w[read_word picture_word].include?(kind) && distinct_pictures(@pictures.first, count: 2).length < 2
    return "memory_word" if kind == "word_pairs" && distinct_pictures(@pictures.first, count: 3).length < 3
    return "memory_word" if kind == "repair_word" && @alphabet.length < 3
    return "write_word" if kind == "fill_letters" && @alphabet.length < 2

    kind
  end

  def select_entry(kind, letter)
    candidates = PICTURE_KINDS.include?(kind) ? @pictures : @pool
    if %w[write_word fill_letters].include?(kind)
      shorter = candidates.select { |entry| entry.fetch("word").length <= 4 }
      candidates = shorter unless shorter.empty?
    end
    candidates.min_by do |entry|
      word = entry.fetch("word")
      [@used_words[word], @recent_words.fetch(word, 0), word.include?(letter.fetch("upper")) ? 0 : 1,
        word.length > 5 ? 1 : 0]
    end
  end

  def trace(letter, letter_case)
    task = common(letter, "trace", letter_case).merge("target" => letter.fetch(letter_case),
      "answer" => letter.fetch(letter_case), "prompt" => "Прати слово.")
    pair = @confusions.find { |item| item.expected_letter_id == letter.fetch("id") }
    task["contrast_letters"] = [pair.expected_letter, pair.chosen_letter].map { |item| item.fetch(letter_case) } if pair
    task
  end

  def build(entry, letter, kind, letter_case, index)
    word = entry.fetch("word")
    task = common(letter, kind, letter_case).merge("word" => word, "answer" => word, "school_word_bank" => true)
    case kind
    when "read_word"
      choices = distinct_pictures(entry).shuffle(random: @random).map do |item|
        { "value" => item.fetch("word"), "label" => item.fetch("emoji"), "image" => item["image"] }
      end
      task.merge("choices" => choices, "options" => choices.map { |choice| choice.fetch("value") },
        "prompt" => "Прочитај реч и пронађи слику.")
    when "picture_word"
      task.merge("emoji" => entry.fetch("emoji"), "image" => entry["image"],
        "options" => distinct_pictures(entry, compare_words: true).map { |item| item.fetch("word") }.shuffle(random: @random),
        "prompt" => "Пронађи реч за слику.")
    when "build_word", "memory_word"
      pair = @confusions.find { |item| word.include?(item.expected_letter.fetch("upper")) }
      task.merge!("tiles" => self.class.tiles(word, letter_ids: @letter_ids,
        distractors: pair ? [pair.chosen_letter.fetch("upper")] : [], random: @random),
        "memory_hidden" => false, "emoji" => kind == "build_word" ? entry.fetch("emoji") : nil,
        "image" => kind == "build_word" ? entry["image"] : nil,
        "prompt" => kind == "build_word" ? "Састави реч за слику." : "Запамти реч, па је састави.")
      task["confusion_checks"] = [{ "expected" => pair.expected_letter_id, "chosen" => pair.chosen_letter_id }] if pair
      task
    when "repair_word"
      repair(task, entry, letter, index)
    when "word_pairs"
      pairs(task, entry)
    when "write_word", "fill_letters"
      writing(task, entry, letter, kind, letter_case)
    end
  end

  def distinct_pictures(entry, count: 4, compare_words: false)
    return [] unless entry

    result = [entry]
    @pictures.shuffle(random: @random).sort_by do |candidate|
      word = candidate.fetch("word")
      # Similar beginnings make children read beyond the first letter. Image
      # ambiguity is still checked below, so every choice has one clear meaning.
      similarity = if compare_words
        target = entry.fetch("word")
        [word.first == target.first ? 0 : 1, (word.length - target.length).abs,
          -word.chars.zip(target.chars).count { |left, right| left == right }]
      else
        []
      end
      [@used_words[word], *similarity, @recent_words.fetch(word, 0)]
    end.each do |candidate|
      next if result.any? { |chosen| SchoolWordBank.visually_ambiguous?(chosen, candidate) }
      result << candidate
      break if result.length >= count
    end
    result
  end

  def repair(task, entry, letter, index)
    word = entry.fetch("word")
    positions = word.chars.each_index.select { |offset| word[offset] == letter.fetch("upper") }
    offset = positions.fetch((@variation + index) % positions.length)
    expected = word[offset]
    alternatives = @alphabet.reject { |char| char == expected }.shuffle(random: @random)
    # A misspelling should not accidentally become another valid known word.
    wrong = alternatives.find do |char|
      candidate = word.dup
      candidate[offset] = char
      !@pool.any? { |item| item.fetch("word") == candidate }
    end
    return build(entry, letter, "build_word", task.fetch("case"), index) unless wrong

    broken = word.dup
    broken[offset] = wrong
    task.merge("emoji" => entry.fetch("emoji"), "image" => entry["image"], "broken_word" => broken,
      "repair_options" => ([expected] + alternatives.reject { |char| char == wrong }.first(3)).shuffle(random: @random),
      "prompt" => "Пронађи и поправи погрешно слово.")
  end

  def pairs(task, entry)
    entries = distinct_pictures(entry, count: 3).shuffle(random: @random)
    picture_ids = %w[P1 P2 P3].shuffle(random: @random)
    words = entries.each_with_index.map { |item, index| { "id" => "W#{index + 1}", "label" => item.fetch("word") } }
    pictures = entries.each_with_index.map { |item, index| { "id" => picture_ids[index], "emoji" => item.fetch("emoji"), "image" => item["image"] } }.shuffle(random: @random)
    pictures.rotate! if pictures.map { |item| item.fetch("id") } == picture_ids
    task.merge("pair_words" => words, "pair_pictures" => pictures, "answer" => picture_ids.join(","),
      "prompt" => "Споји речи са сликама.")
  end

  def writing(task, entry, letter, kind, letter_case)
    word = entry.fetch("word")
    indices = if kind == "write_word"
      (0...word.length).to_a
    else
      first = word.index(letter.fetch("upper")) || 0
      rest = (0...word.length).to_a.reject { |index| index == first }.sort_by { |index| -(index - first).abs }
      [first, *rest.first([[word.length / 2, 2].min - 1, 0].max)].sort
    end
    guides = indices.map do |index|
      source = @letters.find { |item| item.fetch("upper") == word[index] }
      guide = guide_for(source, letter_case).merge("index" => index)
      if kind == "fill_letters"
        pair = @confusions.find { |item| item.expected_letter_id == source.fetch("id") }
        alternates = @letters.reject { |item| item == source }.shuffle(random: @random)
        alternates = ([pair.chosen_letter] + alternates).uniq { |item| item.fetch("id") } if pair
        guide["options"] = ([source] + alternates.first(3)).shuffle(random: @random).map { |item| guide_for(item, letter_case) }
      end
      guide
    end
    pattern = word.chars.each_with_index.map { |char, index| indices.include?(index) ? "_" : (letter_case == "lower" ? char.downcase : char) }.join
    task.merge("emoji" => entry.fetch("emoji"), "image" => entry["image"], "writing_letters" => guides, "word_pattern" => pattern,
      "prompt" => kind == "write_word" ? "Напиши реч, слово по слово." : "Допиши слова која недостају.")
  end

  def guide_for(letter, letter_case)
    { "letter_id" => letter.fetch("id"), "target" => letter.fetch(letter_case),
      "paths" => letter.fetch("strokes").fetch(letter_case) }
  end
end
