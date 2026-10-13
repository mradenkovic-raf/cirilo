class LearningSettings
  class InvalidRequest < StandardError; end

  def self.update!(learner, mode:, selection:, through:, letter_ids:, revision:)
    unless %w[school full].include?(mode)
      raise InvalidRequest, "Изабери школска слова или целу азбуку."
    end

    learner.with_lock do
      unless revision.to_s.match?(/\A\d{1,10}\z/) && revision.to_i == learner.learning_settings_revision
        raise InvalidRequest, "Подешавања су већ промењена. Отвори родитељски преглед поново."
      end

      ids = if mode == "full"
        learner.school_letter_ids
      elsif selection == "through"
        SchoolCurriculum.through(through)
      elsif selection == "custom" && letter_ids.is_a?(Array)
        letter_ids.reject { |id| id == "" }.uniq
      end
      unless SchoolCurriculum.valid_ids?(ids)
        raise InvalidRequest, "Изабери бар једно научено слово."
      end

      learner.update!(learning_mode: mode, school_letter_ids: SchoolCurriculum.canonical_ids(ids),
        learning_settings_revision: learner.learning_settings_revision + 1)
    end
    learner
  end
end
