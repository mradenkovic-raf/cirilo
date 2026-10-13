require "test_helper"

class SchoolPracticePlannerTest < ActiveSupport::TestCase
  READING_KINDS = %w[read_word picture_word build_word memory_word repair_word word_pairs sentence story_action].freeze
  WRITING_KINDS = %w[trace write_word fill_letters].freeze

  test "default school missions mix short reading tasks with two handwriting breaks" do
    learner = Learner.create!
    4.times do |variation|
      tasks = plan(learner, variation: variation)
      assert_equal 12, tasks.length
      assert_equal 10, tasks.count { |task| READING_KINDS.include?(task.fetch("kind")) }
      assert_equal [3, 9], tasks.each_index.select { |index| WRITING_KINDS.include?(tasks[index].fetch("kind")) }
      assert_equal variation.even? ? "write_word" : "fill_letters", tasks.fetch(9).fetch("kind")
      assert_equal [1, 10], tasks.each_index.select { |index| tasks[index].fetch("kind") == "story_action" }
      assert_operator task_words(tasks).uniq.length, :>=, 8
      assert_equal %w[lower upper], tasks.map { |task| task.fetch("case") }.uniq.sort
      tasks.each { |task| assert_scoped(task, learner.school_letter_ids) }
    end
  end

  test "every cumulative stage and every single selected letter remains within its own scope" do
    learner = Learner.create!
    all_ids = SchoolCurriculum.letters.map { |letter| letter.fetch("id") }
    scopes = all_ids.each_index.map { |index| all_ids.first(index + 1) } + all_ids.map { |id| [id] }
    scopes.each do |ids|
      learner.update!(school_letter_ids: ids)
      2.times do |variation|
        tasks = plan(learner, variation: variation)
        assert_equal 12, tasks.length
        tasks.each { |task| assert_scoped(task, ids) }
        assert_operator tasks.count { |task| READING_KINDS.include?(task.fetch("kind")) }, :>=, 10
      end
    end
  end

  test "a week at six missions a day rotates words and task combinations at E" do
    learner = Learner.create!
    words = []
    signatures = []
    42.times do |variation|
      learner.update!(completed_missions: variation)
      tasks = plan(learner, variation: variation)
      words.concat(task_words(tasks))
      signatures << tasks.map { |task| [task["kind"], task["word"], task["story_sentence"], task["case"]] }
      learner.practice_sessions.create!(learning_mode: "school", school_letter_ids: learner.school_letter_ids,
        status: "completed", exercises: tasks, cursor: tasks.length)
    end
    assert_equal 42, signatures.uniq.length
    assert_operator words.uniq.length, :>=, 35
    assert words.all? { |word| word.length <= 6 }
  end

  test "same stage and variation give stable words and stories while fresh task ids remain unique" do
    learner = Learner.create!
    first = plan(learner, variation: 5)
    second = plan(learner, variation: 5)
    content = ->(tasks) { tasks.map { |task| task.slice("kind", "letter_id", "word", "case", "story_sentence") } }
    assert_equal content.call(first), content.call(second)
    assert_empty first.map { |task| task.fetch("id") } & second.map { |task| task.fetch("id") }
  end

  test "school word rotation remembers older missions across letter and mode changes" do
    learner = Learner.create!
    variation = 3
    previous_favorite = plan(learner, variation: variation).first.fetch("word")
    picture_words = SchoolWordBank.picture_entries(learner.school_letter_ids).map { |entry| entry.fetch("word") }
    fresh_word = (picture_words - [previous_favorite]).first
    earlier_ids = SchoolCurriculum.canonical_ids(learner.school_letter_ids + ["r"])
    save_words(learner, [previous_favorite], letter_ids: earlier_ids)
    2.times { save_words(learner, picture_words - [previous_favorite, fresh_word]) }
    learner.practice_sessions.create!(learning_mode: "full", status: "completed", exercises: [], cursor: 0)

    assert_equal fresh_word, plan(learner, variation: variation).first.fetch("word"),
      "A word absent from recent school missions should precede one seen three school missions ago"
  end

  test "all three matching words count toward variety within the mission" do
    learner = Learner.create!
    30.times do |variation|
      tasks = plan(learner, variation: variation)
      words = tasks.flat_map do |task|
        [task["word"], *task.fetch("pair_words", []).map { |pair| pair.fetch("label") }].compact.uniq
      end

      assert_equal words.uniq, words, "Repeated target word in variation #{variation}: #{words.inspect}"
    end
  end

  test "picture word choices encourage reading beyond the initial letter" do
    learner = Learner.create!
    planner = SchoolPracticePlanner.new(learner, letter_ids: learner.school_letter_ids, variation: 5)
    task = planner.send(:build, SchoolWordBank.find("НОС"), Curriculum.find("n"), "picture_word", "upper", 0)

    assert_operator task.fetch("options").count { |word| word.start_with?("Н") }, :>=, 2
    assert_includes task.fetch("options"), "НОС"
    entries = task.fetch("options").map { |word| SchoolWordBank.find(word) }
    entries.combination(2) { |left, right| assert_not SchoolWordBank.visually_ambiguous?(left, right) }
    assert_scoped(task, learner.school_letter_ids)
  end

  test "review focus keeps the last two taught letters and revisits overdue weak known letters" do
    learner = Learner.create!
    learner.school_letter_ids.each do |id|
      learner.letter_progresses.create!(letter_id: id, review_level: 3, next_review_at: 5.days.from_now)
    end
    learner.letter_progresses.find_by!(letter_id: "m").update!(review_level: 0, next_review_at: 1.day.ago)
    learner.letter_progresses.create!(letter_id: "dj", review_level: 0, next_review_at: 10.days.ago)
    assert_equal %w[s e m], SchoolPracticePlanner.next_letters(learner).map { |letter| letter.fetch("id") }

    fresh = Learner.create!
    review_ids = 6.times.map do |variation|
      fresh.update!(completed_missions: variation)
      SchoolPracticePlanner.next_letters(fresh).last.fetch("id")
    end
    assert_equal %w[a m i t o n], review_ids
  end

  test "unknown confusion partners never leak into school tiles handwriting or contrast cues" do
    learner = Learner.create!
    learner.letter_confusions.create!(expected_letter_id: "m", chosen_letter_id: "nj", observations: 4, last_mistake_at: Time.current)
    learner.letter_confusions.create!(expected_letter_id: "n", chosen_letter_id: "i", observations: 2, last_mistake_at: Time.current)
    8.times do |variation|
      plan(learner, variation: variation).each do |task|
        assert_scoped(task, learner.school_letter_ids)
        task.fetch("confusion_checks", []).each do |check|
          assert_includes learner.school_letter_ids, check.fetch("expected")
          assert_includes learner.school_letter_ids, check.fetch("chosen")
        end
      end
    end
  end

  test "review and regenerated tiles use saved letters and have no unrestricted fallback" do
    ids = %w[a m]
    task = SchoolPracticePlanner.reading_review(letter_id: "m", letter_case: "lower", variation: 3, letter_ids: ids)
    assert_scoped(task, ids)
    assert_equal "memory_word", task.fetch("kind")
    assert_includes task.fetch("word"), "М"
    tiles = SchoolPracticePlanner.tiles("МАМА", letter_ids: ids, distractors: %w[Њ Ђ])
    assert_empty tiles - %w[М А]
    assert_equal "МАМА".chars.tally, tiles.tally
    assert_raises(ArgumentError) { SchoolPracticePlanner.reading_review(letter_id: "a", letter_case: "upper", variation: 0, letter_ids: []) }
  end

  test "picture exercises never ask children to identify a name or an ambiguous emoji alternative" do
    learner = Learner.create!
    10.times do |variation|
      plan(learner, variation: variation).each do |task|
        case task.fetch("kind")
        when "read_word", "picture_word"
          entries = task.fetch("options").map { |word| SchoolWordBank.find(word) }
          assert_operator entries.length, :>=, 2
          assert entries.all? { |entry| entry.fetch("picture", true) }
          entries.combination(2) { |left, right| assert_not SchoolWordBank.visually_ambiguous?(left, right) }
        when "word_pairs"
          entries = task.fetch("pair_words").map { |item| SchoolWordBank.find(item.fetch("label")) }
          assert_equal 3, entries.length
          entries.combination(2) { |left, right| assert_not SchoolWordBank.visually_ambiguous?(left, right) }
          assert_not_equal task.fetch("answer").split(","), task.fetch("pair_pictures").map { |picture| picture.fetch("id") }
        when "repair_word"
          assert_nil SchoolWordBank.find(task.fetch("broken_word"))
          assert_equal 1, task.fetch("word").chars.zip(task.fetch("broken_word").chars).count { |left, right| left != right }
        end
      end
    end
  end

  private

  def plan(learner, variation:)
    SchoolPracticePlanner.exercises(learner, letter_ids: learner.school_letter_ids, variation: variation)
  end

  def task_words(tasks)
    tasks.flat_map { |task| [task["word"], *task.fetch("pair_words", []).map { |pair| pair["label"] }] }.compact
  end

  def save_words(learner, words, letter_ids: learner.school_letter_ids)
    exercises = words.map { |word| { "word" => word, "learning_mode" => "school", "school_letter_ids" => letter_ids } }
    learner.practice_sessions.create!(learning_mode: "school", school_letter_ids: letter_ids,
      status: "completed", exercises: exercises, cursor: exercises.length)
  end

  def assert_scoped(task, ids)
    assert_equal "school", task.fetch("learning_mode")
    assert_equal ids, task.fetch("school_letter_ids")
    assert_includes ids, task.fetch("letter_id")
    assert_includes task.fetch("word"), Curriculum.find(task.fetch("letter_id")).fetch("upper") if task["word"]
    %w[word answer target broken_word word_pattern sentence_pattern story_sentence story_context].each do |field|
      assert SchoolCurriculum.known_text?(task[field], ids), "#{field} contains an unknown letter: #{task[field]} for #{ids.inspect}"
    end
    %w[options tiles repair_options contrast_letters].each do |field|
      task.fetch(field, []).each { |value| assert SchoolCurriculum.known_text?(value, ids), "Unknown letter in #{field}: #{value}" }
    end
    task.fetch("choices", []).each { |choice| assert SchoolCurriculum.known_text?(choice["value"], ids) }
    task.fetch("pair_words", []).each { |pair| assert SchoolCurriculum.known_text?(pair.fetch("label"), ids) }
    task.fetch("writing_letters", []).each do |guide|
      ([guide] + guide.fetch("options", [])).each do |option|
        assert_includes ids, option.fetch("letter_id")
        assert SchoolCurriculum.known_text?(option.fetch("target"), ids)
      end
    end
    if task["tiles"]
      task.fetch("word").chars.tally.each { |char, count| assert_equal count, task.fetch("tiles").tally.fetch(char) }
    end
  end
end
