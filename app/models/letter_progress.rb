class LetterProgress < ApplicationRecord
  REVIEW_INTERVALS = [6.hours, 1.day, 3.days, 7.days, 14.days, 30.days].freeze
  RECALL_KINDS = %w[build_word read_word sentence memory_word picture_word repair_word].freeze

  belongs_to :learner
  validates :letter_id, presence: true, uniqueness: { scope: :learner_id }
  validates :correct_count, :incorrect_count, :review_level,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def due?
    next_review_at.nil? || next_review_at <= Time.current
  end

  def familiar?
    review_level >= 3
  end

  def progress_percent
    [review_level * 20, 100].min
  end

  def record_practice!(correct:, kind:, recall_eligible: true, now: Time.current)
    self.last_practiced_at = now
    if correct
      self.correct_count += 1
      # Tracing shows motor practice, not unaided recognition. Repeated tasks
      # during one sitting also must not count as remembering across days.
      if recall_eligible && RECALL_KINDS.include?(kind) && (last_reviewed_at.nil? || last_reviewed_at <= now - 12.hours)
        self.review_level = [review_level + 1, REVIEW_INTERVALS.length].min
        self.last_reviewed_at = now
        self.next_review_at = now + REVIEW_INTERVALS.fetch(review_level - 1)
      end
      self.next_review_at ||= now + 6.hours
    else
      self.incorrect_count += 1
      self.review_level = [review_level - 1, 0].max if RECALL_KINDS.include?(kind)
      self.next_review_at = now + 10.minutes
    end
    save!
  end
end
