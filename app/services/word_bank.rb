class WordBank
  PREFERRED = {
    "А" => "АУТО", "Б" => "БРОД", "В" => "ВУК", "Г" => "ГЉИВА", "Д" => "ДРВО", "Ђ" => "ЂАВО",
    "Е" => "ЕКРАН", "Ж" => "ЖАБА", "З" => "ЗЕЦ", "И" => "ИГЛА", "Ј" => "ЈАЈЕ", "К" => "КИТ",
    "Л" => "ЛАВ", "Љ" => "ЉУДИ", "М" => "МИШ", "Н" => "НОС", "Њ" => "ЊУШКА", "О" => "ОКО",
    "П" => "ПУЖ", "Р" => "РИБА", "С" => "САТ", "Т" => "ТОРТА", "Ћ" => "ЋУРКА", "У" => "УВО",
    "Ф" => "ФОКА", "Х" => "ХЛЕБ", "Ц" => "ЦРВ", "Ч" => "ЧАША", "Џ" => "ЏИП", "Ш" => "ШАЛ"
  }.freeze

  class << self
    def words
      @words ||= JSON.parse(Rails.root.join("config/words.json").read).freeze
    end

    def find(word)
      words.find { |entry| entry.fetch("word") == word }
    end

    def for_letter(letter, variation: 0, excluding: [])
      upper = letter.fetch("upper")
      candidates = words.select { |entry| entry.fetch("word").start_with?(upper) }
      candidates = words.select { |entry| entry.fetch("word").include?(upper) } if candidates.empty?
      preferred = find(PREFERRED.fetch(upper))
      candidates = [preferred, *(candidates - [preferred])] if candidates.include?(preferred)
      ordered = candidates.rotate(variation % candidates.length)
      ordered.find { |entry| !excluding.include?(entry.fetch("word")) } || ordered.first
    end

    def picture_choices(entry)
      others = words.reject { |item| visually_ambiguous?(entry, item) }
      related = others.select { |item| item.fetch("category") == entry.fetch("category") }.shuffle
      choices = [entry]
      (related + (others - related).shuffle).each do |item|
        next if choices.any? { |chosen| visually_ambiguous?(chosen, item) }
        choices << item
        break if choices.length == 4
      end
      choices.shuffle.map { |item| { "value" => item.fetch("word"), "label" => item.fetch("emoji") } }
    end

    # Different emoji can still mean the same thing to a beginning reader.
    # Share this rule across read-a-word, picture-word and matching exercises.
    def visually_ambiguous?(left, right)
      left.fetch("word") == right.fetch("word") || left.fetch("emoji") == right.fetch("emoji") ||
        (left["picture_group"].present? && left["picture_group"] == right["picture_group"])
    end

    def tiles(word, distractors: [])
      extra = distractors.uniq.first(2)
      random = Curriculum.letters.map { |letter| letter.fetch("upper") }.reject { |letter| word.include?(letter) || extra.include?(letter) }.sample(2 - extra.length)
      result = (word.chars + extra + random).shuffle
      result.rotate! if result.first(word.length).join == word
      result
    end
  end
end
