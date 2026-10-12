class ShopReset
  class InvalidRequest < StandardError; end

  def self.reset!(learner, confirmation:, reset_word:, generation:)
    unless confirmation == "1" && reset_word == "RESET"
      raise InvalidRequest, "Означи потврду и упиши RESET да вратиш XP и куповине на почетак."
    end

    learner.with_lock do
      unless ShopService.current_generation?(learner, generation)
        raise InvalidRequest, "Продавница је већ промењена. Отвори родитељски преглед поново."
      end

      learner.shop_purchases.delete_all
      learner.update!(xp: 0, xp_spent: 0, selected_dino: "rex", dino_color: "green",
        selected_theme: "meadow", selected_effect: "stars", shop_generation: learner.shop_generation + 1)
    end
    learner
  end
end
