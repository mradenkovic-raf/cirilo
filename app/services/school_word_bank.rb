class SchoolWordBank
  class << self
    def words
      @words ||= JSON.parse(Rails.root.join("config/school_words.json").read).map do |entry|
        entry.each_value(&:freeze)
        entry.freeze
      end.freeze
    end

    def find(word)
      normalized = word.to_s.unicode_normalize(:nfc).upcase
      words.find { |entry| entry.fetch("word") == normalized }
    end

    # Apply the same restriction to answers and distractors. Unknown or empty
    # selections must never silently fall back to the full alphabet.
    def eligible(letter_ids)
      allowed = Array(letter_ids).filter_map { |id| Curriculum.find(id)&.fetch("upper") }.uniq
      words.select { |entry| (entry.fetch("word").chars - allowed).empty? }
    end

    def picture_entries(letter_ids)
      eligible(letter_ids).select { |entry| entry.fetch("picture", true) }
    end

    def image_paths
      @image_paths ||= words.filter_map { |entry| entry["image"] }.uniq.freeze
    end

    def image_url(entry)
      path = entry&.fetch("image", nil)
      return unless image_paths.include?(path)

      digest = Digest::SHA256.file(Rails.public_path.join(path.delete_prefix("/"))).hexdigest.first(12)
      "#{path}?v=#{digest}"
    end

    def visually_ambiguous?(left, right)
      left_picture = left["image"] || left.fetch("emoji")
      right_picture = right["image"] || right.fetch("emoji")
      left.fetch("word") == right.fetch("word") || left_picture == right_picture ||
        (left["picture_group"].present? && left["picture_group"] == right["picture_group"])
    end

    # The caller supplies an already scoped pool. Fewer than count pictures is
    # a normal result in the earliest stages; callers can choose another task.
    def distinct_pictures(entry, pool, count: 4)
      return [] if count < 1 || !entry&.fetch("picture", true)
      return [] unless pool.any? { |candidate| candidate.fetch("word") == entry.fetch("word") }

      candidates = pool.select { |candidate| candidate.fetch("picture", true) }.shuffle
      related, others = candidates.partition { |candidate| candidate.fetch("category") == entry.fetch("category") }
      choices = [entry]
      (related + others).each do |candidate|
        break if choices.length >= count
        next if choices.any? { |chosen| visually_ambiguous?(chosen, candidate) }

        choices << candidate
      end
      choices.shuffle
    end
  end
end
