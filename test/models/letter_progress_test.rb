require "test_helper"

class LetterProgressTest < ActiveSupport::TestCase
  setup do
    @progress = Learner.current.letter_progresses.create!(letter_id: Curriculum.letters.first.fetch("id"))
  end

  test "repeating in the same sitting does not pretend to be long term recall" do
    now = Time.zone.parse("2026-10-11 12:00:00")
    4.times { @progress.record_practice!(correct: true, kind: "build_word", now: now) }
    assert_equal 4, @progress.correct_count
    assert_equal 1, @progress.review_level
    assert_equal now + 6.hours, @progress.next_review_at

    @progress.record_practice!(correct: true, kind: "read_word", now: now + 1.day)
    assert_equal 2, @progress.review_level
    assert_equal now + 2.days, @progress.next_review_at
  end

  test "tracing is rewarded as practice but is not unaided recall" do
    @progress.record_practice!(correct: true, kind: "trace")
    assert_equal 1, @progress.correct_count
    assert_equal 0, @progress.review_level
    assert_nil @progress.last_reviewed_at
  end

  test "a mistake requests an early review without touching earned rewards" do
    now = Time.current
    @progress.update!(review_level: 3)
    @progress.record_practice!(correct: false, kind: "read_word", now: now)
    assert_equal 2, @progress.review_level
    assert_in_delta (now + 10.minutes).to_f, @progress.next_review_at.to_f, 0.001
    assert_equal 1, @progress.incorrect_count
    assert_equal 0, @progress.learner.xp
  end

  test "a hinted or corrected success records practice without advancing recall" do
    @progress.record_practice!(correct: true, kind: "memory_word", recall_eligible: false)
    assert_equal 1, @progress.correct_count
    assert_equal 0, @progress.review_level
    assert_nil @progress.last_reviewed_at
  end
end
