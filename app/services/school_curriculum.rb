class SchoolCurriculum
  ORDER = %w[А М И Т О Н С Е Р Ј У Ш Л Љ З В Г П К Д Б Њ Х Ж Ч Ћ Ф Ц Џ Ђ].freeze
  DEFAULT_LETTER_IDS = %w[a m i t o n s e].freeze

  class << self
    def default_ids
      DEFAULT_LETTER_IDS.dup
    end

    def letters
      @letters ||= ORDER.map { |upper| Curriculum.letters.find { |letter| letter.fetch("upper") == upper } }.freeze
    end

    def canonical_ids(ids)
      letters.filter_map { |letter| letter.fetch("id") if Array(ids).include?(letter.fetch("id")) }
    end

    def letters_for(ids)
      letters.select { |letter| Array(ids).include?(letter.fetch("id")) }
    end

    def through(id)
      index = letters.index { |letter| letter.fetch("id") == id }
      index && letters.first(index + 1).map { |letter| letter.fetch("id") }
    end

    def valid_ids?(ids)
      ids.is_a?(Array) && ids.any? && ids.all? { |id| id.is_a?(String) && Curriculum.find(id) } && ids.uniq == ids
    end

    def known_text?(text, ids)
      (text.to_s.upcase.scan(/[А-ЯЂЈЉЊЋЏ]/) - letters_for(ids).map { |letter| letter.fetch("upper") }).empty?
    end
  end
end
