class Curriculum
  LEARNING_ORDER = %w[А М И О Т Е С Н Р У К В П Л Д Ј Б Г З Ж Ш Ч Ћ Ц Ђ Ф Х Љ Њ Џ].freeze
  PARTS = [
    ["boots", "Турбо чизмице", "🚀", "Још један део за нашег истраживача."],
    ["tail", "Репни појачивач", "🦕", "Нови реп помаже диносауру да држи равнотежу."],
    ["chest", "Храбро срце", "💚", "Мало храбро срце покреће велику авантуру!"],
    ["antenna", "Радар антена", "📡", "Наш другар сада открива далеке сигнале."],
    ["shoulders", "Штитови за рамена", "🤖", "Робо-делови су спремни за нову авантуру."],
    ["fins", "Енергетска леђа", "✨", "Нови део чува енергију за истраживање."],
    ["goggles", "Истраживачке наочаре", "🥽", "Диносаур је спреман за далека путовања."],
    ["jetpack", "Млазни ранац", "🚀", "Клик сада може да полети! Још осам изненађења чека у радионици."],
    ["cape", "Плашт храбрости", "🦸", "Плашт за друга који се не предаје кад слово буде тешко."],
    ["crown", "Круна истраживача", "👑", "Клик носи круну коју сте освојили заједно!"],
    ["shield", "Светлосни штит", "🛡️", "Упалио се нови светлосни штит. Спремни за следећи изазов!"],
    ["rocket_boots", "Ракетне чизмице", "🔥", "Потисници су укључени. Време је за дино-скок!"],
    ["star_badge", "Звезда знања", "⭐", "Златна звезда за сва слова која сте заједно вежбали."],
    ["headphones", "Музичке слушалице", "🎧", "Клик је добио слушалице. Притисни Плес и прославите!"],
    ["guardians", "Дронови чувари", "🛸", "Два мала дрона сада прате Клика у свакој авантури."],
    ["pedestal", "Холо-постоље", "💎", "Свих 16 делова је твоје! Сада освајаш кристале енергије."]
  ].freeze

  class << self
    def letters
      # Shared by single-letter guides and saved word-writing tasks. The print
      # stroke reference and pedagogical choices are in qa/v14/IZVORI-POTEZA.md.
      @letters ||= begin
        data = JSON.parse(Rails.root.join("config/alphabet.json").read)
        data = data.fetch("letters") if data.is_a?(Hash)
        data.map { |letter| letter.merge("id" => letter.fetch("id").to_s) }.freeze
      end
    end

    def find(id)
      letters.find { |letter| letter["id"] == id.to_s }
    end

    def ordered_letters
      letters.sort_by { |letter| LEARNING_ORDER.index(letter["upper"]) || 99 }
    end

    def parts
      PARTS.each_index.map { |index| part_at(index + 1) }
    end

    def part_at(position)
      position = position.to_i
      spec = PARTS[position - 1] if position.positive?
      key, name, emoji, description = spec || ["energy_#{position}", "Кристал енергије #{[position - PARTS.length, 1].max}", "💠", "Још једна завршена мисија, још један кристал за твог диносаура!"]
      { "id" => key, "key" => key, "name" => name, "title" => name,
        "emoji" => emoji, "description" => description, "position" => position }
    end
  end
end
