class Learner < ApplicationRecord
  has_many :letter_progresses, dependent: :destroy
  has_many :practice_sessions, dependent: :destroy
  has_many :attempts, dependent: :destroy
  has_many :part_unlocks, dependent: :destroy
  has_many :battles, dependent: :destroy
  has_many :shop_purchases, dependent: :destroy
  has_many :letter_confusions, dependent: :destroy

  validates :singleton_key, inclusion: { in: ["child"] }, uniqueness: true
  validates :xp, :completed_missions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :dinosaur_generation, numericality: { only_integer: true, greater_than: 0 }
  validates :shop_generation, numericality: { only_integer: true, greater_than: 0 }
  validates :xp_spent, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :xp }
  validates :dino_color, inclusion: { in: ShopCatalog.values_for("color") }
  validates :selected_dino, inclusion: { in: ShopCatalog.values_for("dino") }
  validates :selected_theme, inclusion: { in: ShopCatalog.values_for("theme") }
  validates :selected_effect, inclusion: { in: ShopCatalog.values_for("effect") }

  def self.current
    find_by(singleton_key: "child") || create_or_find_by!(singleton_key: "child")
  end

  def active_session
    practice_sessions.find_by(status: "active")
  end

  def level
    (xp / 100) + 1
  end

  def xp_balance
    xp - xp_spent
  end

  def owns_shop_item?(item_or_id)
    item = ShopCatalog.resolve(item_or_id)
    return false unless item
    item.fetch("price").zero? || shop_purchases.exists?(item_key: item.fetch("id"))
  end

  def selected_shop_item?(item_or_id)
    item = ShopCatalog.resolve(item_or_id)
    item.present? && self[ShopCatalog.selection_attribute(item)] == item.fetch("value")
  end

  def shop_requirement(item_or_id)
    item = ShopCatalog.resolve(item_or_id)
    return if !item || owns_shop_item?(item)

    ShopCatalog.previous_paid_items(item).find { |previous| !owns_shop_item?(previous) }
  end

  def can_restore_dino?
    last_dino_snapshot.present? && !part_unlocks.exists?
  end

  def statistics
    practiced = letter_progresses.where("correct_count > 0")
    {
      xp: xp, xp_balance: xp_balance, level: level, missions: completed_missions,
      letters_practiced: practiced.count,
      letters_remembered: practiced.where("review_level >= 3").count,
      letters_total: Curriculum.letters.length,
      parts: part_unlocks.count,
      due_letters: practiced.where("next_review_at <= ?", Time.current).count,
      correct_attempts: attempts.where(correct: true).count
    }
  end
end
