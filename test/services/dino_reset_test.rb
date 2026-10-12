require "test_helper"

class DinoResetTest < ActiveSupport::TestCase
  setup do
    @learner = test_learner
    @learner.update!(xp: 500, completed_missions: 9, dino_color: "blue")
    9.times do |index|
      session = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
      part = Curriculum.part_at(index + 1)
      @learner.part_unlocks.create!(practice_session: session, part_key: part.fetch("id"), position: index + 1)
    end
    @progress = @learner.letter_progresses.create!(letter_id: "a", correct_count: 12,
      incorrect_count: 3, review_level: 2, next_review_at: 1.day.from_now)
    @active = @learner.practice_sessions.create!(exercises: [{ "id" => "existing", "kind" => "recognize",
      "letter_id" => "a", "answer" => "А", "options" => ["А", "М", "О", "Т"] }])
    @attempt = @active.attempts.create!(learner: @learner, exercise_id: "older", letter_id: "a",
      kind: "recognize", answer: "М", correct: false)
  end

  test "reset removes only the collection and color and saves a recoverable snapshot" do
    history = learning_history
    DinoReset.reset!(@learner, confirmation: "1", generation: 1)

    assert_equal 0, @learner.part_unlocks.count
    assert_equal "green", @learner.reload.dino_color
    assert_equal 2, @learner.dinosaur_generation
    assert_equal 9, @learner.last_dino_snapshot.fetch("unlocks").size
    assert_equal "blue", @learner.last_dino_snapshot.fetch("dino_color")
    assert @learner.can_restore_dino?
    assert_equal history, learning_history
  end

  test "confirmation and an exact current generation are required" do
    [nil, "0", true, ["1"], { "confirm" => "1" }].each do |confirmation|
      assert_raises(DinoReset::InvalidRequest) do
        DinoReset.reset!(@learner, confirmation: confirmation, generation: "1")
      end
    end
    [nil, "", "01", "1x", "2", 1.0, ["1"], { "id" => 1 }].each do |generation|
      assert_raises(DinoReset::InvalidRequest) do
        DinoReset.reset!(@learner, confirmation: "1", generation: generation)
      end
    end
    assert_equal 9, @learner.part_unlocks.count
    assert_equal "blue", @learner.reload.dino_color
    assert_equal 1, @learner.dinosaur_generation
  end

  test "replayed reset cannot overwrite the snapshot or repeatedly advance the generation" do
    DinoReset.reset!(@learner, confirmation: "1", generation: "1")
    snapshot = @learner.last_dino_snapshot.deep_dup
    assert_raises(DinoReset::InvalidRequest) { DinoReset.reset!(@learner, confirmation: "1", generation: "1") }
    assert_raises(DinoReset::InvalidRequest) { DinoReset.reset!(@learner, confirmation: "1", generation: "2") }
    assert_equal 2, @learner.reload.dinosaur_generation
    assert_equal snapshot, @learner.last_dino_snapshot
  end

  test "restore returns the old rewards and color without affecting learning or accepting old forms" do
    rewards = @learner.part_unlocks.order(:position).pluck(:practice_session_id, :part_key, :position)
    history = learning_history
    DinoReset.reset!(@learner, confirmation: "1", generation: "1")
    DinoReset.restore!(@learner, generation: "2")

    assert_equal rewards, @learner.part_unlocks.order(:position).pluck(:practice_session_id, :part_key, :position)
    assert_equal "blue", @learner.reload.dino_color
    assert_equal 3, @learner.dinosaur_generation
    assert_equal({}, @learner.last_dino_snapshot)
    assert_not @learner.can_restore_dino?
    assert_equal history, learning_history
    assert_raises(DinoReset::InvalidRequest) { DinoReset.reset!(@learner, confirmation: "1", generation: "1") }
    assert_raises(DinoReset::InvalidRequest) { DinoReset.restore!(@learner, generation: "2") }
  end

  test "recoloring and resetting an empty dino preserves the original recoverable collection" do
    rewards = @learner.part_unlocks.order(:position).pluck(:practice_session_id, :part_key, :position)
    history = learning_history
    DinoReset.reset!(@learner, confirmation: "1", generation: "1")
    snapshot = @learner.reload.last_dino_snapshot.deep_dup

    @learner.update!(dino_color: "peach")
    DinoReset.reset!(@learner, confirmation: "1", generation: "2")
    assert_equal snapshot, @learner.reload.last_dino_snapshot
    assert_equal "green", @learner.dino_color
    assert_equal 3, @learner.dinosaur_generation
    assert @learner.can_restore_dino?

    DinoReset.restore!(@learner, generation: "3")
    assert_equal rewards, @learner.part_unlocks.order(:position).pluck(:practice_session_id, :part_key, :position)
    assert_equal "blue", @learner.reload.dino_color
    assert_equal history, learning_history
  end

  test "completing the retained mission awards the first part and disables restore" do
    DinoReset.reset!(@learner, confirmation: "1", generation: "1")
    result = AttemptRecorder.new(@active).submit!(exercise_id: "existing", answer: "А")

    assert result[:completed]
    assert_equal "boots", @active.reload.part_unlock.part_key
    assert_equal 1, @active.part_unlock.position
    assert_equal 10, @learner.reload.completed_missions
    assert_equal 535, @learner.xp
    assert_not @learner.can_restore_dino?
    assert_raises(DinoReset::InvalidRequest) { DinoReset.restore!(@learner, generation: "2") }
    assert_equal 1, @learner.part_unlocks.count
  end

  test "a failed learner update rolls back removed rewards" do
    @learner.update_columns(completed_missions: -1)
    assert_raises(ActiveRecord::RecordInvalid) do
      DinoReset.reset!(@learner, confirmation: "1", generation: "1")
    end
    assert_equal 9, @learner.part_unlocks.count
    assert_equal "blue", @learner.reload.dino_color
    assert_equal 1, @learner.dinosaur_generation
  end

  private

  def learning_history
    [@learner.reload.xp, @learner.completed_missions,
      @progress.reload.attributes, @active.reload.attributes, @attempt.reload.attributes,
      @learner.practice_sessions.count]
  end
end
