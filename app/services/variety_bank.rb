class VarietyBank
  SIMILAR_LETTERS = [%w[А Д], %w[Б В], %w[Г Т], %w[Е З], %w[И Н], %w[К Х],
    %w[Л Љ], %w[М Н], %w[Н Њ], %w[О С], %w[П Р], %w[Ц Ч], %w[Ћ Ђ], %w[Ш Џ]].freeze

  class << self
    def picture_word(entry, variation: 0)
      pool = ranked_alternatives(entry).first(8).rotate(variation % 3)
      entries = distinct_pictures(entry, pool, count: 4)
      { "word" => entry.fetch("word"), "answer" => entry.fetch("word"),
        "emoji" => entry.fetch("emoji"), "image" => entry["image"],
        "options" => entries.map { |item| item.fetch("word") }.shuffle,
        "prompt" => "Шта је на слици? Пронађи реч." }
    end

    def repair_word(entry, letter:, variation: 0)
      word = entry.fetch("word")
      positions = word.chars.each_index.select { |index| word[index] == letter.fetch("upper") }
      index = positions.fetch(variation % positions.length)
      expected = word[index]
      alternatives = similar_letters(expected) + alphabet.reject { |char| char == expected }.shuffle
      wrong = alternatives.first
      broken = word.dup
      broken[index] = wrong
      options = ([expected] + alternatives.reject { |char| char == wrong }.uniq.first(3)).shuffle
      { "word" => word, "answer" => word, "emoji" => entry.fetch("emoji"),
        "image" => entry["image"],
        "broken_word" => broken, "repair_options" => options,
        "prompt" => "Једно слово је погрешно. Поправи реч." }
    end

    def word_pairs(entry, variation: 0)
      pool = ranked_alternatives(entry).first(8).rotate(variation % 4)
      entries = distinct_pictures(entry, pool, count: 3).shuffle
      # The image IDs do not encode their matching word IDs. Only the persisted
      # answer knows that relationship; the browser receives the two lists.
      picture_ids = %w[P1 P2 P3].shuffle
      words = entries.each_with_index.map { |item, index| { "id" => "W#{index + 1}", "label" => item.fetch("word") } }
      pictures = entries.each_with_index.map do |item, index|
        { "id" => picture_ids[index], "emoji" => item.fetch("emoji") }.tap do |picture|
          picture["image"] = item["image"] if item["image"]
        end
      end.shuffle
      pictures.rotate! if pictures.map { |item| item.fetch("id") } == picture_ids
      { "pair_words" => words, "pair_pictures" => pictures,
        "answer" => picture_ids.join(","), "prompt" => "Споји сваку реч са њеном сликом." }
    end

    private

    def alphabet
      Curriculum.letters.map { |letter| letter.fetch("upper") }
    end

    def similar_letters(letter)
      SIMILAR_LETTERS.select { |pair| pair.include?(letter) }.flatten.uniq - [letter]
    end

    def distinct_pictures(entry, pool, count:)
      entries = [entry]
      pool.each do |candidate|
        next if entries.any? { |chosen| visually_ambiguous?(chosen, candidate) }
        entries << candidate
        break if entries.length == count
      end
      entries
    end

    def ranked_alternatives(entry)
      target = entry.fetch("word")
      WordBank.words.reject { |candidate| visually_ambiguous?(entry, candidate) }.sort_by do |candidate|
        word = candidate.fetch("word")
        [edit_distance(target, word), word.first == target.first ? 0 : 1,
          -(target.chars & word.chars).length, candidate.fetch("category") == entry.fetch("category") ? 0 : 1, word]
      end
    end

    def visually_ambiguous?(left, right)
      WordBank.visually_ambiguous?(left, right)
    end

    def edit_distance(left, right)
      row = (0..right.length).to_a
      left.chars.each_with_index do |char, index|
        next_row = [index + 1]
        right.chars.each_with_index do |other, offset|
          next_row << [next_row.last + 1, row[offset + 1] + 1, row[offset] + (char == other ? 0 : 1)].min
        end
        row = next_row
      end
      row.last
    end
  end
end
