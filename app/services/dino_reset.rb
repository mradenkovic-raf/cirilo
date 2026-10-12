class DinoReset
  class InvalidRequest < StandardError; end

  UNLOCK_ATTRIBUTES = %w[practice_session_id part_key position created_at updated_at].freeze

  class << self
    def reset!(learner, confirmation:, generation:)
      unless confirmation == "1"
        raise InvalidRequest, "Прво потврди да желиш да започнеш новог диносаура."
      end

      learner.with_lock do
        verify_generation!(learner, generation)
        has_parts = learner.part_unlocks.exists?
        if !has_parts && learner.dino_color == "green"
          raise InvalidRequest, "Дино већ чека свој први део. Можеш да наставиш мисију."
        end

        # Recoloring an empty dino is not a new reward. Keep the original
        # recoverable collection if the parent resets that color again.
        snapshot = if !has_parts && learner.last_dino_snapshot.present?
          learner.last_dino_snapshot
        else
          {
            "dino_color" => learner.dino_color,
            "saved_at" => Time.current.iso8601,
            "unlocks" => learner.part_unlocks.order(:position).map do |unlock|
              unlock.attributes.slice(*UNLOCK_ATTRIBUTES)
            end
          }
        end
        learner.part_unlocks.delete_all
        learner.update!(dino_color: "green", dinosaur_generation: learner.dinosaur_generation + 1,
          last_dino_snapshot: snapshot)
      end
      learner
    end

    def restore!(learner, generation:)
      learner.with_lock do
        verify_generation!(learner, generation)
        unless learner.can_restore_dino?
          raise InvalidRequest, "Претходне делове можеш да вратиш само пре освајања нове награде."
        end

        snapshot = learner.last_dino_snapshot
        snapshot.fetch("unlocks").each do |attributes|
          learner.part_unlocks.create!(attributes.slice(*UNLOCK_ATTRIBUTES))
        end
        # Keep this version monotonic: a form opened before reset or restore
        # must never be able to apply that old action for a second time.
        color = snapshot.fetch("dino_color")
        color = "green" unless learner.owns_shop_item?("color_#{color}")
        learner.update!(dino_color: color,
          dinosaur_generation: learner.dinosaur_generation + 1, last_dino_snapshot: {})
      end
      learner
    end

    private

    def verify_generation!(learner, value)
      valid = value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A[1-9]\d{0,8}\z/))
      unless valid && value.to_i == learner.dinosaur_generation
        raise InvalidRequest, "Дино је већ промењен. Погледај радионицу пре нове измене."
      end
    end
  end
end
