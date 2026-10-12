class BattleArena
  class InvalidBattle < StandardError; end
  class InvalidMove < StandardError; end
  class StaleMove < StandardError; end

  MOVES = %w[attack guard feint].freeze
  BEATS = { "attack" => "feint", "guard" => "attack", "feint" => "guard" }.freeze

  def self.start!(learner, practice_session)
    learner.with_lock do
      practice_session.reload
      unless practice_session.learner_id == learner.id
        raise ActiveRecord::RecordNotFound, "Мисија није пронађена."
      end
      unless practice_session.completed?
        raise InvalidBattle, "Прво заврши мисију, па изађи са својим диносаурусом у арену."
      end
      existing = learner.battles.find_by(practice_session_id: practice_session.id)
      next existing if existing

      gear = learner.part_unlocks.order(:position).map do |unlock|
        part = unlock.part
        { "position" => unlock.position, "key" => unlock.part_key,
          "name" => part.fetch("name"), "emoji" => part.fetch("emoji") }
      end
      player_hp = Battle::BASE_HP + gear.length
      enemy_hp = Battle::BASE_HP + (gear.length * 0.75).ceil
      learner.battles.create!(practice_session: practice_session, dino_color: learner.dino_color,
        dino_species: learner.selected_dino,
        gear_snapshot: gear, player_hp: player_hp, player_max_hp: player_hp,
        enemy_hp: enemy_hp, enemy_max_hp: enemy_hp)
    end
  end

  def self.state(battle)
    last = battle.turn_history.last || {}
    {
      id: battle.id, practice_session_id: battle.practice_session_id,
      status: battle.status, round: battle.round, action_revision: battle.action_revision,
      player_hp: battle.player_hp, player_max_hp: battle.player_max_hp,
      enemy_hp: battle.enemy_hp, enemy_max_hp: battle.enemy_max_hp,
      base_hp: battle.base_hp, armor_remaining: battle.armor_remaining,
      gear_count: battle.gear_count, dino_color: battle.dino_color, dino_species: battle.dino_species,
      gear: battle.gear_snapshot.deep_dup, remaining_gear: battle.remaining_gear.deep_dup,
      player_move: last["player_move"], enemy_move: last["enemy_move"],
      outcome: last["outcome"], dropped_part: last["dropped_part"],
      powers: Battle::POWER_PARTS.to_h { |power, _| [power, {
        owned: !!battle.owns_power?(power), used: battle.power_used?(power),
        available: battle.active? && !!battle.owns_power?(power) && !battle.power_used?(power),
        armed: power == "shield" && battle.shield_armed?
      }] },
      revealed_enemy_move: battle.active? && battle.power_used?("goggles") &&
        battle.power_state.dig("goggles", "round") == battle.round ? battle.next_enemy_move : nil,
      shield_armed: battle.shield_armed?,
      pending_power: pending_power(battle),
      feedback: feedback(battle, last), medal: battle.status == "won" ? "victory" : nil
    }
  end

  def self.pending_power(battle)
    return unless battle.active?
    return "goggles" if battle.power_used?("goggles") && battle.power_state.dig("goggles", "round") == battle.round
    return "shield" if battle.shield_armed? && battle.power_state.dig("shield", "activation_revision") == battle.action_revision - 1
  end

  def self.feedback(battle, last)
    return "Победа! Освојио си медаљу за ову мисију!" if battle.status == "won"
    if battle.status == "lost"
      return "Овог пута противник је победио. Твоја опрема је сачувана за следећу борбу."
    end

    case last["outcome"]
    when "blocked" then "Светлосни штит је зауставио погодак! Сви животи и делови су сачувани."
    when "dodge" then "Ракете су те склониле! Ову рунду нико није погођен."
    when "win" then "Погодак! Противник губи један живот."
    when "tie" then "Нерешено! Нико није изгубио живот. Изабери следећи потез."
    when "lose"
      last["dropped_part"] ? "Део опреме је отпао, али твој дино се бори даље!" : "Противник те је погодио. Изабери следећи потез!"
    else "Изабери потез. Противник бира свој — па откривамо оба!"
    end
  end

  def initialize(battle, enemy_picker: nil, random: SecureRandom)
    @battle = battle
    @enemy_picker = enemy_picker
    @random = random
  end

  def move!(move:, expected_round:, expected_revision: nil)
    unless move.is_a?(String) && MOVES.include?(move)
      raise InvalidMove, "Изабери напад, штит или варку."
    end
    round = validated_round(expected_round)
    revision = expected_revision.nil? ? nil : validated_revision(expected_revision)

    with_current_battle_lock do
      if round < @battle.round
        previous = @battle.turn_history[round]
        if previous && previous["player_move"] == move
          next self.class.state(@battle).merge(success: true, duplicate: true)
        end
        raise StaleMove, "Ова рунда је већ одиграна. Настави од тренутног стања."
      end
      unless round == @battle.round
        raise StaleMove, "Стање борбе се променило. Настави од тренутне рунде."
      end
      unless @battle.active?
        raise StaleMove, "Ова борба је завршена. Следећа завршена мисија отвара нову борбу."
      end
      validate_current_revision!(revision) unless revision.nil?
      resolve_turn!(move)
    end
  end

  def power!(power:, expected_round:, expected_revision:)
    unless power.is_a?(String) && Battle::POWER_PARTS.key?(power)
      raise InvalidMove, "Изабери наочаре, светлосни штит или ракете."
    end
    round = validated_round(expected_round)
    revision = validated_revision(expected_revision)

    with_current_battle_lock do
      prior = @battle.power_state[power]
      if prior && prior["used"] && prior["round"] == round && prior["activation_revision"] == revision
        next self.class.state(@battle).merge(success: true, duplicate: true)
      end
      unless @battle.active? && round == @battle.round
        raise StaleMove, "Стање борбе се променило. Погледај тренутни потез."
      end
      validate_current_revision!(revision)
      raise InvalidMove, "Ова моћ тражи свој део опреме. Освоји га у мисијама." unless @battle.owns_power?(power)
      raise StaleMove, "Ову моћ си већ искористио у овој борби." if @battle.power_used?(power)

      powers = @battle.power_state.deep_dup
      powers[power] = { "used" => true, "round" => round, "activation_revision" => revision }
      powers[power]["armed"] = true if power == "shield"
      @battle.power_state = powers
      if power == "rockets"
        next resolve_turn!("dodge")
      end
      committed_enemy_move! if power == "goggles"
      @battle.action_revision += 1
      @battle.save!
      self.class.state(@battle).merge(success: true, duplicate: false)
    end
  end

  private

  def with_current_battle_lock(&block)
    # Match mission/reset lock order. An already-loaded battle must reload only
    # after a full restart has either completed or waited for this turn.
    @battle.learner.with_lock do
      @battle.with_lock(&block)
    end
  end

  def committed_enemy_move!(player_move: nil)
    return @battle.next_enemy_move if @battle.next_enemy_move
    move = if @enemy_picker
      @enemy_picker.call
    else
      # Starting health fixes the difficulty for this match. Losing a heart
      # never secretly changes the odds, and revealed moves stay committed.
      @opponent ||= BattleOpponent.new(player_hp: @battle.player_max_hp,
        enemy_hp: @battle.enemy_max_hp, random: @random)
      @opponent.pick(player_move: player_move)
    end
    raise ArgumentError, "invalid enemy move" unless MOVES.include?(move)
    @battle.next_enemy_move = move
  end

  def resolve_turn!(move)
    # A revealed choice is committed in SQLite and is never drawn again.
    enemy_move = committed_enemy_move!(player_move: move)
    outcome = if move == "dodge"
      "dodge"
    elsif move == enemy_move
      "tie"
    elsif BEATS.fetch(move) == enemy_move
      "win"
    else
      "lose"
    end
    dropped_part = nil
    if outcome == "win"
      @battle.enemy_hp -= 1
    elsif outcome == "lose"
      if @battle.shield_armed?
        powers = @battle.power_state.deep_dup
        powers["shield"]["armed"] = false
        powers["shield"]["blocked_round"] = @battle.round
        @battle.power_state = powers
        outcome = "blocked"
      else
        dropped_part = @battle.remaining_gear.last&.deep_dup
        @battle.player_hp -= 1
      end
    end
    @battle.round += 1
    @battle.action_revision += 1
    @battle.next_enemy_move = nil
    @battle.turn_history = @battle.turn_history + [{
      "round" => @battle.round, "player_move" => move, "enemy_move" => enemy_move,
      "outcome" => outcome, "dropped_part" => dropped_part,
      "player_hp" => @battle.player_hp, "enemy_hp" => @battle.enemy_hp
    }]
    if @battle.enemy_hp.zero? || @battle.player_hp.zero?
      @battle.status = @battle.enemy_hp.zero? ? "won" : "lost"
      @battle.finished_at = Time.current
    end
    @battle.save!
    self.class.state(@battle).merge(success: true, duplicate: false)
  end

  def validate_current_revision!(revision)
    unless revision == @battle.action_revision
      raise StaleMove, "Моћи или потези су се променили. Арена је освежена. Изабери поново."
    end
  end

  def validated_revision(value)
    validated_round(value)
  end

  def validated_round(value)
    valid = (value.is_a?(Integer) && value >= 0) ||
      (value.is_a?(String) && value.match?(/\A(?:0|[1-9]\d{0,8})\z/))
    raise InvalidMove, "Недостаје број тренутне рунде. Отвори борбу поново." unless valid
    value.to_i
  end
end
