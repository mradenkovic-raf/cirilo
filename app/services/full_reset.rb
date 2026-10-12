class FullReset
  class InvalidRequest < StandardError; end

  def self.reset!(learner, confirmation:, reset_word:, shop_generation:, dinosaur_generation:)
    unless confirmation == "1" && reset_word == "RESET"
      raise InvalidRequest, "Означи потврду и упиши RESET за потпуно нов почетак."
    end

    learner.with_lock do
      valid_dino_generation = (dinosaur_generation.is_a?(Integer) && dinosaur_generation.positive?) ||
        (dinosaur_generation.is_a?(String) && dinosaur_generation.match?(/\A[1-9]\d{0,8}\z/))
      unless ShopService.current_generation?(learner, shop_generation) &&
          valid_dino_generation && dinosaur_generation.to_i == learner.dinosaur_generation
        raise InvalidRequest, "Напредак је већ промењен. Отвори родитељски преглед поново."
      end

      # Keep the learner and monotonic generations: old browser forms must not
      # become valid again. Delete children first to respect foreign keys.
      learner.attempts.delete_all
      learner.battles.delete_all
      learner.part_unlocks.delete_all
      learner.practice_sessions.delete_all
      learner.letter_progresses.delete_all
      learner.letter_confusions.delete_all
      learner.shop_purchases.delete_all
      learner.update!(xp: 0, xp_spent: 0, completed_missions: 0,
        selected_dino: "rex", dino_color: "green", selected_theme: "meadow", selected_effect: "stars",
        last_dino_snapshot: {}, egg_state: {}, shop_generation: learner.shop_generation + 1,
        dinosaur_generation: learner.dinosaur_generation + 1)
    end
    learner
  end
end
