class EggCompanion
  class Error < StandardError; end

  CHOICES = { "rex" => "Рексић", "tricera" => "Трицератопс", "stego" => "Стегосаурус" }.freeze
  MISSIONS_TO_HATCH = 3

  def initialize(learner)
    @learner = learner
  end

  def state
    @learner.egg_state
  end

  def chosen?
    state.present?
  end

  def species
    state["species"]
  end

  def stage
    return 0 unless chosen?
    (@learner.completed_missions - state.fetch("started_missions")).clamp(0, MISSIONS_TO_HATCH)
  end

  def ready?
    chosen? && stage == MISSIONS_TO_HATCH && !hatched?
  end

  def hatched?
    state["hatched"] == true
  end

  def name
    state.fetch("name", "")
  end

  def choose!(species:, generation:)
    unless species.is_a?(String) && CHOICES.key?(species)
      raise Error, "Изабери једно од три јајета."
    end

    @learner.with_lock do
      unless ShopService.current_generation?(@learner, generation)
        raise Error, "Отвори своје двориште поново, па изабери јаје."
      end
      if chosen?
        raise Error, "Већ имаш своје јаје!" unless self.species == species
        next false
      end

      @learner.update!(egg_state: { "id" => SecureRandom.uuid, "species" => species,
        "started_missions" => @learner.completed_missions, "hatched" => false, "name" => "" })
      true
    end
  end

  def hatch!(egg_id:)
    @learner.with_lock do
      verify_egg!(egg_id)
      next false if hatched?
      raise Error, "Заврши три мисије после избора јајета." unless ready?

      @learner.update!(egg_state: state.merge("hatched" => true))
      true
    end
  end

  def name!(egg_id:, name:)
    normalized = normalize_name!(name)
    @learner.with_lock do
      verify_egg!(egg_id)
      raise Error, "Прво помози свом другару да се излегне." unless hatched?
      if self.name.present?
        raise Error, "Твој другар већ има име." unless self.name == normalized
        next false
      end

      @learner.update!(egg_state: state.merge("name" => normalized))
      true
    end
  end

  private

  def verify_egg!(egg_id)
    unless egg_id.is_a?(String) && chosen? && egg_id == state["id"]
      raise Error, "Ово јаје више није ту. Отвори своје двориште поново."
    end
  end

  def normalize_name!(value)
    if value.is_a?(String) && value.valid_encoding? && value.length <= 100
      normalized = value.unicode_normalize(:nfc).strip.gsub(/[[:space:]]+/, " ")
      return normalized if normalized.length.between?(1, 20) &&
        normalized.match?(/\A\p{L}[\p{L}\p{M}]*(?:[ -]\p{L}[\p{L}\p{M}]*)*\z/)
    end
    raise Error, "Упиши име од 1 до 20 слова. Можеш да користиш размак или цртицу."
  end
end
