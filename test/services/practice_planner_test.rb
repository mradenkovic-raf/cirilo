require "test_helper"
require_relative "exercise_helpers"

class PracticePlannerTest < ActiveSupport::TestCase
  include ExerciseHelpers

  test "mission persists with twelve interleaved reading writing and memory tasks" do
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
      assert tasks.any? { |exercise| %w[trace write_word fill_letters].include?(exercise["kind"]) }
    end
    assert_equal({ "trace" => 2, "write_word" => 2, "fill_letters" => 2, "repair_word" => 1,
      "picture_word" => 1, "story_action" => 1, "word_pairs" => 1, "memory_word" => 2 },
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
    exercises = PracticePlanner::MISSION_PLAN.filter_map do |kind, letter_index|
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
    exercises = PracticePlanner::MISSION_PLAN.map do |kind, letter_index|
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

  test "three mission cycle varies reading without reducing writing memory or mission length" do
    learner = test_learner
    kinds = []
    6.times do |variation|
      learner.update!(completed_missions: variation)
      session = PracticePlanner.start!(learner)
      tally = session.exercises.map { |item| item.fetch("kind") }.tally
      kinds.concat(tally.keys)
      assert_equal 12, session.total_exercises
      assert_equal 2, tally["trace"]
      assert_equal 2, tally["write_word"]
      assert_equal 2, tally["fill_letters"]
      assert_equal 2, tally["memory_word"]
      assert_equal 1, tally["story_action"]
      assert (tally.keys & %w[picture_word repair_word word_pairs]).any?
      assert_equal %w[build_word read_word sentence].sort, (kinds & %w[build_word read_word sentence]).sort if variation % 3 == 2
      session.update!(status: "completed")
    end
    assert_equal %w[build_word fill_letters memory_word picture_word read_word repair_word sentence story_action trace word_pairs write_word], kinds.uniq.sort
  end
end
