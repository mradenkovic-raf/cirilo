require "test_helper"
require_relative "exercise_helpers"

class PracticePlannerTest < ActiveSupport::TestCase
  include ExerciseHelpers

  LEGACY_MISSION_PLAN = [
    ["trace", 0], ["write_word", 1], ["read_word", 2], ["memory_word", 0],
    ["fill_letters", 2], ["sentence", 0], ["trace", 1], ["write_word", 2],
    ["story_action", 1], ["build_word", 2], ["fill_letters", 0], ["memory_word", 1]
  ].freeze
  READING_KINDS = %w[read_word picture_word build_word repair_word word_pairs sentence memory_word story_action].freeze
  WRITING_KINDS = %w[trace write_word fill_letters].freeze

  test "mission persists with ten reading and letter tasks plus two handwriting tasks" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    resumed = PracticePlanner.start!(Learner.find(learner.id))
    assert_equal session.id, resumed.id
    assert_equal session.exercises, resumed.reload.exercises
    assert_equal 12, session.total_exercises
    assert_equal 3, session.focus_letters.length
    assert_equal 1, learner.practice_sessions.count
    session.focus_letters.each do |letter_id|
      tasks = session.exercises.select { |exercise| exercise["letter_id"] == letter_id }
      assert_equal 4, tasks.length
      assert_operator tasks.count { |exercise| READING_KINDS.include?(exercise["kind"]) }, :>=, 3
    end
    assert_equal({ "trace" => 1, "write_word" => 1, "repair_word" => 1,
      "picture_word" => 1, "read_word" => 2, "build_word" => 1, "sentence" => 1,
      "story_action" => 2, "word_pairs" => 1, "memory_word" => 1 },
      session.exercises.map { |exercise| exercise["kind"] }.tally)
    assert_equal %w[lower upper], session.exercises.map { |exercise| exercise["case"] }.uniq.sort
    session.exercises.each do |exercise|
      assert_equal PracticePlanner::VERSION, exercise["version"]
      if exercise["options"]
        assert_includes exercise["options"], exercise["answer"]
        assert_equal 4, exercise["options"].uniq.length
      end
      next if %w[trace story_action word_pairs].include?(exercise["kind"])
      assert_includes exercise["word"], Curriculum.find(exercise["letter_id"])["upper"]
      assert_not_includes exercise["prompt"], exercise["answer"]
      if exercise["tiles"]
        assert_equal exercise["answer"].length + 2, exercise["tiles"].length
        exercise["answer"].chars.tally.each do |char, count|
          assert_equal count, exercise["tiles"].tally.fetch(char)
        end
      end
      if exercise["kind"] == "read_word"
        assert_equal exercise["options"], exercise["choices"].map { |choice| choice["value"] }
        assert_equal 4, exercise["choices"].map { |choice| choice["label"] }.uniq.length
      end
      assert_nil exercise["emoji"] if %w[memory_word sentence read_word].include?(exercise["kind"])
      if exercise["writing_letters"]
        exercise["writing_letters"].each do |letter|
          assert_equal exercise["word"][letter["index"]], letter["target"].upcase
          assert_equal Curriculum.find(letter["letter_id"])["strokes"][exercise["case"]], letter["paths"]
        end
        if exercise["kind"] == "write_word"
          assert_equal exercise["word"].length, exercise["writing_letters"].length
        else
          assert_includes 1..2, exercise["writing_letters"].length
          assert_operator exercise["word_pattern"].count("_"), :<=, exercise["word"].length / 2
          exercise["writing_letters"].each do |letter|
            assert_equal 4, letter["options"].map { |option| option["target"] }.uniq.length
            assert_includes letter["options"].map { |option| option["target"] }, letter["target"]
          end
        end
      end
    end
  end

  test "two reviews accompany one new letter and every letter is eventually introduced" do
    learner = test_learner
    Curriculum.ordered_letters.first(3).each do |letter|
      learner.letter_progresses.create!(letter_id: letter["id"], review_level: 1, next_review_at: 1.day.ago)
    end
    while learner.letter_progresses.count < 30
      before = learner.letter_progresses.pluck(:letter_id)
      selected = PracticePlanner.next_letters(learner)
      new_letters = selected.reject { |letter| before.include?(letter["id"]) }
      assert_equal 3, selected.length
      assert_equal 1, new_letters.length
      new_letters.each { |letter| learner.letter_progresses.create!(letter_id: letter["id"]) }
    end
    assert_equal 3, PracticePlanner.next_letters(learner).length
  end

  test "overdue weak letters are revisited before recent familiar letters" do
    learner = test_learner
    letters = Curriculum.ordered_letters.first(4)
    letters.each_with_index do |letter, index|
      learner.letter_progresses.create!(letter_id: letter["id"], review_level: index,
        next_review_at: index < 2 ? 1.day.ago : 7.days.from_now)
    end
    selected = PracticePlanner.next_letters(learner).map { |letter| letter["id"] }
    assert_equal letters.first(2).map { |letter| letter["id"] }, selected.first(2)
  end

  test "upgrade preserves completed work and replaces only unanswered legacy tasks" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    original = 10.times.map do |index|
      { "id" => "old-#{index}", "kind" => "recognize", "letter_id" => "a", "answer" => "А", "options" => %w[А М И О] }
    end
    session.update!(exercises: original, cursor: 3, earned_xp: 30)
    learner.update!(xp: 30)
    PracticePlanner.upgrade!(session)
    assert_equal original.first(3), session.reload.exercises.first(3)
    assert_equal 3, session.cursor
    assert_equal 30, session.earned_xp
    assert_equal 30, learner.reload.xp
    assert_equal 12, session.total_exercises
    assert session.exercises.drop(3).all? { |exercise| exercise["version"] == PracticePlanner::VERSION }
    assert_equal session.exercises, PracticePlanner.start!(learner).exercises
  end

  test "completed legacy missions are never changed by upgrade" do
    session = PracticePlanner.start!(test_learner)
    original = [{ "id" => "old-finished", "kind" => "word" }]
    session.update!(exercises: original, cursor: 1, status: "completed", earned_xp: 125)
    PracticePlanner.upgrade!(session)
    assert_equal original, session.reload.exercises
    assert_equal 125, session.earned_xp
  end

  test "upgrading a long v2 mission keeps completed IDs and at least one remaining task" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    original = 15.times.map { |index| { "id" => "v2-#{index}", "version" => 2, "kind" => "read_word" } }
    session.update!(exercises: original, cursor: 14, earned_xp: 130)
    learner.update!(xp: 130)
    PracticePlanner.upgrade!(session)
    assert_equal original.first(14), session.reload.exercises.first(14)
    assert_equal 14, session.cursor
    assert_equal 15, session.total_exercises
    assert_equal PracticePlanner::VERSION, session.current_exercise["version"]
    assert_equal 130, session.earned_xp
    assert_equal 130, learner.reload.xp
    assert_not session.completed?
  end

  test "an unfinished v3 mission keeps IDs order drawings protocol memory state and recovery" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    exercises = LEGACY_MISSION_PLAN.filter_map do |kind, letter_index|
      next if kind == "story_action"
      planned_exercise(kind, letter_id: session.focus_letters.fetch(letter_index), version: 3)
    end
    memory = exercises.find { |item| item["kind"] == "memory_word" }
    memory["memory_hidden"] = true
    recovery = exercises.first.deep_dup.merge("id" => "saved-recovery", "recovery_of" => memory.fetch("id"), "review_only" => true)
    exercises.insert(2, recovery)
    session.update!(exercises: exercises, cursor: 2, earned_xp: 20)
    learner.update!(xp: 20)
    assert_equal exercises, PracticePlanner.upgrade!(session).exercises
    assert_equal exercises, PracticePlanner.start!(learner).exercises
    assert_equal 2, session.reload.cursor
    assert_equal 20, learner.reload.xp
  end

  test "unfinished v4 mission retains its exact order answer choices memory state and XP" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    exercises = LEGACY_MISSION_PLAN.map do |kind, letter_index|
      planned_exercise(kind, letter_id: session.focus_letters.fetch(letter_index), version: 4)
    end
    exercises.find { |item| item["kind"] == "memory_word" }["memory_hidden"] = true
    session.update!(exercises: exercises, cursor: 3, earned_xp: 30)
    learner.update!(xp: 30)
    assert_equal exercises, PracticePlanner.upgrade!(session).exercises
    assert_equal exercises, PracticePlanner.start!(learner).exercises
    assert_equal 3, session.reload.cursor
    assert_equal 30, session.earned_xp
    assert_equal 30, learner.reload.xp
  end

  test "unfinished v5 mission keeps all six handwriting tasks recovery memory and already earned XP" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    exercises = LEGACY_MISSION_PLAN.map do |kind, letter_index|
      planned_exercise(kind, letter_id: session.focus_letters.fetch(letter_index), version: 5)
    end
    memory = exercises.find { |item| item["kind"] == "memory_word" }
    memory["memory_hidden"] = true
    recovery = exercises.first.deep_dup.merge("id" => "v5-saved-recovery", "recovery_of" => memory.fetch("id"),
      "review_only" => true, "extra_review" => true)
    exercises.insert(3, recovery)
    session.update!(exercises: exercises, cursor: 3, earned_xp: 30)
    learner.update!(xp: 30)

    assert_equal exercises, PracticePlanner.upgrade!(session).reload.exercises
    assert_equal exercises, PracticePlanner.start!(learner).reload.exercises
    assert_equal 3, session.reload.cursor
    assert_equal 30, session.earned_xp
    assert_equal 30, learner.reload.xp
  end

  test "successive missions keep reading dominant and alternate full word with missing letter handwriting" do
    learner = test_learner
    kinds = []
    6.times do |variation|
      learner.update!(completed_missions: variation)
      session = PracticePlanner.start!(learner)
      task_kinds = session.exercises.map { |item| item.fetch("kind") }
      kinds.concat(task_kinds)
      assert_equal 12, session.total_exercises
      assert_equal 10, task_kinds.count { |kind| READING_KINDS.include?(kind) }
      assert_equal 2, task_kinds.count { |kind| WRITING_KINDS.include?(kind) }
      assert_equal "read_word", task_kinds.first
      assert_equal [3, 9], task_kinds.each_index.select { |index| WRITING_KINDS.include?(task_kinds[index]) }
      assert_equal variation.even? ? "write_word" : "fill_letters", task_kinds.fetch(9)
      assert_equal 1, task_kinds.count("trace")
      assert_equal 1, task_kinds.count("memory_word")
      assert_equal 2, task_kinds.count("story_action")
      assert_equal [1, 10], task_kinds.each_index.select { |index| task_kinds[index] == "story_action" }
      assert_equal "position", session.exercises.fetch(1).fetch("story_dimension")
      assert_includes %w[size place action], session.exercises.fetch(10).fetch("story_dimension")
      assert_equal %w[lower upper], session.exercises.map { |item| item.fetch("case") }.uniq.sort
      session.focus_letters.each do |letter_id|
        tasks = session.exercises.select { |item| item.fetch("letter_id") == letter_id }
        assert_equal 4, tasks.length
        assert_operator tasks.count { |item| READING_KINDS.include?(item.fetch("kind")) }, :>=, 3
      end
      session.update!(status: "completed")
    end
    assert_equal (READING_KINDS + WRITING_KINDS).sort, kinds.uniq.sort
  end

  test "unfinished v6 mission retains its reading mix choices memory recovery and XP" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    exercises = session.exercises.deep_dup
    exercises.each { |exercise| exercise["version"] = 6 }
    # Restore the V6 picture task that occupied the new position-story slot.
    letter = Curriculum.find(session.focus_letters.fetch(1))
    entry = WordBank.for_letter(letter)
    exercises[1] = PracticePlanner.send(:exercise, letter, entry, "picture_word", "upper")
      .merge(VarietyBank.picture_word(entry, variation: 0)).merge("version" => 6)
    exercises.find { |item| item["kind"] == "memory_word" }["memory_hidden"] = true
    recovery = exercises.first.deep_dup.merge("id" => "v6-saved-recovery", "review_only" => true,
      "extra_review" => true, "recovery_of" => exercises.fetch(4).fetch("id"))
    exercises.insert(4, recovery)
    session.update!(exercises: exercises, cursor: 4, earned_xp: 30)
    learner.update!(xp: 30)

    assert_equal exercises, PracticePlanner.upgrade!(session).reload.exercises
    assert_equal exercises, PracticePlanner.start!(learner).reload.exercises
    assert_equal 4, session.reload.cursor
    assert_equal 30, session.earned_xp
    assert_equal 30, learner.reload.xp
    assert_equal 2, session.exercises.count { |item| item["kind"] == "picture_word" }
    assert_equal 1, session.exercises.count { |item| item["kind"] == "story_action" }
  end

  test "mission rotation includes all position sentences and keeps the twelve original story sentences" do
    learner = test_learner
    positions = []
    original_stories = []
    20.times do |variation|
      learner.update!(completed_missions: variation)
      session = PracticePlanner.start!(learner)
      positions << session.exercises.fetch(1).fetch("story_sentence")
      original_stories << session.exercises.fetch(10).fetch("story_sentence")
      assert_equal StoryBank.position_exercise(variation: variation).fetch("story_sentence"), positions.last
      assert_equal StoryBank.exercise(variation: variation).fetch("story_sentence"), original_stories.last
      session.update!(status: "completed")
    end
    assert_equal 20, positions.uniq.length
    assert_equal 12, original_stories.uniq.length
  end

  test "reading led missions still award exactly 145 XP and one equipment part for either writing variation" do
    learner = test_learner
    2.times do |variation|
      session = PracticePlanner.start!(learner)
      assert_equal variation.even? ? "write_word" : "fill_letters", session.exercises.fetch(9).fetch("kind")
      before_xp = learner.reload.xp
      complete_practice_session(session)
      assert_equal 145, session.reload.earned_xp
      assert_equal before_xp + 145, learner.reload.xp
      assert_equal variation + 1, learner.completed_missions
      assert_equal variation + 1, learner.part_unlocks.count
    end
  end
end
